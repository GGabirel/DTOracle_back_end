// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

import "../storage/TaskPerformStorage.sol";
import "../storage/TaskPrepareStorage.sol";
import "../storage/TaskCreatStorage.sol";
import "../storage/TaskWorkerStorage.sol";
import "../storage/TaskRequesterStorage.sol";
import "../storage/UserStorage.sol";

    /**
        本合约内容为执行任务阶段相关函数的逻辑实现，包含:
            发包者：开始任务（包含检测候选者接受情况和开始任务）、指令评估（包含检测发包者提交情况）
            接包者：预提交、提交
     */

contract TaskPerformImpl {

    TaskPerformStorage public performStorage;
    TaskPrepareStorage public prepareStorage;
    TaskCreatStorage public creatStorage;
    TaskWorkerStorage public workerStorage;
    TaskRequesterStorage public requesterStorage;
    UserStorage public userStorage;

    constructor(UserStorage _userStorage, TaskWorkerStorage _workerStorage, TaskRequesterStorage _requesterStorage, TaskCreatStorage _creatStorage, TaskPrepareStorage  _prepareStorage, TaskPerformStorage _performStorage) {
        userStorage = _userStorage;
        workerStorage = _workerStorage;
        requesterStorage = _requesterStorage;
        performStorage =_performStorage;
        creatStorage = _creatStorage;
        prepareStorage = _prepareStorage;
    }

	event LogWorkerPreSubmited(address indexed _submitter, address indexed _task, bytes32 _sealedMessage, uint _time);
	event LogWorkerSubmited(address indexed _submitter, address indexed _task,int16[] _message, uint _time);
	event LogTaskStateModified(address indexed _task, address indexed _who, uint _time, uint8 _newstate);

    modifier checkTimeIn(uint _endTime) {
		require(block.timestamp < _endTime,"Out of time!");
		_;
	}

	modifier checkTimeOut(uint _endTime) {
		require(block.timestamp > _endTime,"Too early!");
		_;
	}

    modifier checkRequester(address _task ,address _requester) {
		require(creatStorage.TaskToRequester(_task) == _requester,"Not requester");
		_;
	}

	modifier checkState(address _task, uint8 _state) {
		require(creatStorage.getTaskState(_task) == _state,"Wrong State");
		_;
	}

    // 分两个函数
    function checkAccept(address _task, address _requester) external
        checkRequester(_task, _requester) 
        checkTimeOut(creatStorage.getAcceptTimeEnd(_task))
		checkTimeIn(creatStorage.getStartTimeEnd(_task))
        checkState(_task,1) 
    {
        //检测是第一次检测
        uint8 _taskCount = creatStorage.TasksCur(_task);
        bool checkAccepted = requesterStorage.getCheckAccepted(_task, _taskCount);
        require(!checkAccepted,"Have CheckAccepted");

        //检测委员会人数是否达到最低要求：未达到解散
        if(prepareStorage.getCommitteeNumbers(_task,_taskCount)  < creatStorage.getWorkersMin(_task, _taskCount)) {
            //解散委员会,TS状态回退，W状态回退，扣除相应信誉值，本次结束（Next+1）
            address[] memory candidaters= prepareStorage.getTasksCandidaters(_task, _taskCount);
            for(uint i = 0; i< candidaters.length; i++ ) {
                if(!workerStorage.getAccepted(_task, _taskCount, candidaters[i])) {
                    //未接受，扣除相应信誉值-5
                    userStorage.subWorkerRep(candidaters[i], 1);
                }
                //回退候选者状态
                if(userStorage.getWorkerRep(candidaters[i]) >= 0) {
                    userStorage.changeStateToOnline(candidaters[i]);
                } else {
                    userStorage.changeStateToOffline(candidaters[i]);
                }
            }
        }

        //修改发包者的checkAccepted状态位
        requesterStorage.setCheckAccepted(_task, _taskCount);
        //回退任务状态至Fresh
        creatStorage.setTaskState(_task, 0);
    }

    
    function startTask(address _task, address _requester, string memory _details, uint _prePayment) external
        checkRequester(_task, _requester) 
        checkTimeOut(creatStorage.getAcceptTimeEnd(_task))
		checkTimeIn(creatStorage.getStartTimeEnd(_task))
    {
        //检测 是否检查候选者反馈
        uint8 _taskCount = creatStorage.TasksCur(_task);
        bool checkAccepted = requesterStorage.getCheckAccepted(_task, _taskCount);
        require(checkAccepted,"Haven't CheckAccepted");
        //检测预估款项
        require(creatStorage.getPrePaymentCur(_task) == _prePayment,"Wrong PrePayment!");
  
        _changeStorage(_task, _taskCount, _requester, _details, _prePayment);

    }

    function _changeStorage(address _task, uint8 _taskCount,address _requester, string memory _details, uint _prePayment) internal {
        //creatStorage:修改任务详情文本(creat)、任务状态
        creatStorage.setStartTask(_task, _taskCount, _details);
        //requesterStorage:设置发包者开始标志位、发包者余额
        requesterStorage.setStartTask(_task, _taskCount, _prePayment);
        //performStorage:初始化标签数组、正确结果数组(有无必要？)
        performStorage.setStartTask(_task, _taskCount, creatStorage.getImageNumber(_task, _taskCount), prepareStorage.getCommitteeNumbers(_task, _taskCount));

        //userStorage:接包者成员状态改变
        address[] memory workers = prepareStorage.getCommitteeAddrs(_task, _taskCount);
        for(uint i = 0; i< workers.length; i++) {
            userStorage.changeStateToBusy(workers[i]);
        }

		emit LogTaskStateModified(_task, _requester, block.timestamp, 2);
    } 


    function preSubmit(address _task, address _worker, bytes32 _commitment) external 
        checkTimeOut(creatStorage.getStartTimeEnd(_task))
		checkTimeIn(creatStorage.getPreSubmitTimeEnd(_task))
        checkState(_task,2) 
    {
        //检测接包者状态
        require(userStorage.getUserState(_worker) == 4,"Not Busy");
        //检测调用者为本次委员会成员
        uint8 _taskCount = creatStorage.TasksCur(_task);
        require(workerStorage.getAccepted(_task, _taskCount, _worker),"Not Committee Memeber");
        //检测重复
        address[] memory workers = prepareStorage.getCommitteeAddrs(_task, _taskCount);
        for(uint8 i = 0; i < workers.length; i++) {
            require(workerStorage.getResultHash(_task, _taskCount, workers[i])!= _commitment ,"Same as others,choose another random");
        }
        //TaskStorage:预提交信息
        workerStorage.presubmit(_task, _taskCount, _worker, _commitment);
        
        //触发预提交事件
        emit LogWorkerPreSubmited(_worker, _task, _commitment, block.timestamp);
    }



    function submit(address _task, address _worker, int16[] memory _result, uint _random) external 
        checkTimeOut(creatStorage.getPreSubmitTimeEnd(_task))
		checkTimeIn(creatStorage.getSubmitTimeEnd(_task))
        checkState(_task,2)  
    {
        //检测接包者状态
        require(userStorage.getUserState(_worker) == 4,"Not Busy");
        //检测调用者为本次委员会成员
        uint8 _taskCount = creatStorage.TasksCur(_task);
        require(workerStorage.getAccepted(_task, _taskCount, _worker),"Not Committee Memeber");
        //检测是否一致
        require(keccak256(abi.encodePacked(_result ,_random)) == workerStorage.getResultHash(_task, _taskCount, _worker),"Not Same as RandomHash");
        //检测是否和subTaskId一致
        uint8 index = workerStorage.getWorkerIndex(_task, _taskCount, _worker);
        int16[] memory subTaskId = prepareStorage.getSubTaskIdByIndex(_task, _taskCount, index);
        require(_result.length == subTaskId.length,"length error");
        for(uint i = 0; i < _result.length; i++) {
            if(subTaskId[i] == -1)
                require(_result[i] == -1, "Wrong Label");
        }

        //修改提交信息
        workerStorage.submit(_task, _taskCount, _worker, _result);
        
        //触发提交事件
        emit LogWorkerSubmited(_worker, _task, _result, block.timestamp);
    }

    //检测提交情况
    function checkSubmit(address _task, address _requester) external 
        checkRequester(_task, _requester) 
        checkTimeOut(creatStorage.getSubmitTimeEnd(_task))
		checkTimeIn(creatStorage.getEvaluateTimeEnd(_task))
        checkState(_task,2)
    {
        //只能检测一次
        uint8 _taskCount = creatStorage.TasksCur(_task);
        require(!requesterStorage.getCheckSubmited(_task, _taskCount),"Have checkSubmited");

        _checkSubmit2(_task, _taskCount,_requester);


    }

    function _checkSubmit2(address _task, uint8 _taskCount, address _requester) internal {
        //对没进行提交或预提交的的接包者处罚:信誉和扣除押金(补偿给发包者)
        address[] memory workers = prepareStorage.getCommitteeAddrs(_task, _taskCount);
        uint submitNumber = workers.length;
        for(uint8 i = 0; i < workers.length; i++) {
            if(!workerStorage.getPreSubmited(_task, _taskCount, workers[i])) {
                userStorage.subWorkerRep(workers[i], 5);
                if(userStorage.getWorkerRep(workers[i]) >= 0) {
                    userStorage.changeStateToOnline(workers[i]);
                } else {
                    userStorage.changeStateToOffline(workers[i]);
                }
                submitNumber--;
                //扣除承诺费
                workerStorage.setWorkerBalance(_task, _taskCount, workers[i], workerStorage.getBalance(_task, _taskCount, workers[i]) - creatStorage.getCommlFee(_task));
                //扣除报名费
                workerStorage.setEnrollFeeToZero(_task, _taskCount, workers[i]);
                //将承诺费和报名费补偿给发包者
                requesterStorage.setRequesterBalance(_task, _taskCount, requesterStorage.getRequesterBalance(_task, _taskCount) + creatStorage.getCommlFee(_task) + creatStorage.getEnrollFee(_task));
            } else if(!workerStorage.getSubmited(_task, _taskCount, workers[i])) {
                userStorage.subWorkerRep(workers[i], 10);
                if(userStorage.getWorkerRep(workers[i]) >= 0) {
                    userStorage.changeStateToOnline(workers[i]);
                } else {
                    userStorage.changeStateToOffline(workers[i]);
                }
                submitNumber--;
                //扣除承诺费
                workerStorage.setWorkerBalance(_task, _taskCount, workers[i],workerStorage.getBalance(_task, _taskCount, workers[i]) - creatStorage.getCommlFee(_task));
                //扣除报名费
                workerStorage.setEnrollFeeToZero(_task, _taskCount, workers[i]);
                //将承诺费和报名费补偿给发包者
                requesterStorage.setRequesterBalance(_task, _taskCount, requesterStorage.getRequesterBalance(_task, _taskCount) + creatStorage.getCommlFee(_task) + creatStorage.getEnrollFee(_task));
            }
        }

        //改变众包状态：Completed 3  or Failed 4
        if(submitNumber == 0) {
            creatStorage.setTaskState(_task, 4);
            emit LogTaskStateModified(_task, _requester, block.timestamp, 4);
        } else {
            creatStorage.setTaskState(_task, 3);
            creatStorage.setSubmitNumber(_task, uint8(submitNumber));
            emit LogTaskStateModified(_task, _requester, block.timestamp, 3);
        }

        //设置发包者标志位
        requesterStorage.setCheckSubmited(_task, _taskCount);
    }

	//质量评估时需要的数据结构，每次用完都会删掉
	mapping(address => mapping(int => uint8)) private TaskTolabelCount;
	mapping(address =>int[]) private TaskTolabls;

    function evaluate(address _task, address _requester) external 
        checkRequester(_task, _requester) 
        checkTimeOut(creatStorage.getSubmitTimeEnd(_task))
		checkTimeIn(creatStorage.getEvaluateTimeEnd(_task))
        checkState(_task,3) 
        returns(address[] memory, uint[] memory)
    {
        //逻辑过于复杂，拆成两个子函数
        uint8 _taskCount = creatStorage.TasksCur(_task);
        address[] memory workers = prepareStorage.getCommitteeAddrs(_task, _taskCount);

        //评估正确结果
        _getRightLabels(_task, _taskCount, workers);
        //评估接包者奖励
        _calRewards(_task, _taskCount, workers);

        return (workers, performStorage.getWorkersRewards(_task, _taskCount));
    }

    function _getRightLabels(address _task, uint8 _taskCount, address[] memory workers) public {
        //计算正确数组
        for(uint16 j = 0; j< performStorage.getRightLabels(_task, _taskCount).length; j++) {
            int16 MaxResult = -1;
			uint8 MaxResultCount = 0;
			uint8 submitNumber = 0;

            for(uint8 i =0; i < workers.length; i++) {
                //确保已经提交结果
                if(workerStorage.getResultLength(_task, _taskCount, workers[i]) != 0) {
                    int16 curLabel = workerStorage.getResultByIndex(_task, _taskCount, workers[i], j);

                    // 如果label[i][j] == -1,直接下一个
					if(curLabel == -1) 
						continue;
					
					//合法标签，对应++
					submitNumber++;
					TaskTolabelCount[_task][curLabel]++;

                    //判断是否超出半数,若超出直接设置正确答案，并进行下一个图片的评估
					if(TaskTolabelCount[_task][curLabel] >= workers.length /2 +1) {
						performStorage.setRightByIndex(_task, _taskCount, j, curLabel);
						break;
					}

                    //判断是否初次出现，是的话加到图片j的标签组里
					if(TaskTolabelCount[_task][curLabel] == 1) 
						TaskTolabls[_task].push(curLabel);

					//不是初次出现，判断是否为次数最多,相等：不对，出现多众数；
					if(TaskTolabelCount[_task][curLabel] > MaxResultCount) {
						MaxResult = curLabel;
						MaxResultCount = TaskTolabelCount[_task][curLabel];
					}
                }
            }
            //比对完毕，判断众数是否符合要求,符合要求，设置正确答案。
            if( MaxResultCount >= submitNumber /2 + 1) {
                performStorage.setRightByIndex(_task, _taskCount, j, MaxResult);
            }

            //删除标签统计信息
			for(uint i =0; i < TaskTolabls[_task].length; i++) {
				delete TaskTolabelCount[_task][TaskTolabls[_task][i]];
			}
			delete TaskTolabls[_task];
        }
    }

    function _calRewards(address _task, uint8 _taskCount, address[] memory workers) public {

        uint8 taskType = creatStorage.TasksToType(_task, _taskCount);
        for(uint8 i = 0; i< workers.length; i++) {
            if(workerStorage.getResultLength(_task, _taskCount, workers[i]) != 0) {
                //计算正确个数
                uint16 rightCount = 0;
                for(uint16 j = 0; j< performStorage.getRightLabels(_task, _taskCount).length; j++) {
                    if(performStorage.getRightLabelByIndex(_task, _taskCount, j) == workerStorage.getResultByIndex(_task, _taskCount, workers[i], j)) {
                        rightCount++;
                    }
                }

                //修改正确个数
                workerStorage.setRightCount(_task, _taskCount, workers[i], rightCount);
                //计算标注奖励
                uint reward = rightCount * creatStorage.getRewardFeeCur(_task);
                //设置对应接包者报酬
                performStorage.setRewardsByIndex(_task, _taskCount, i, reward);
                //扣除发包者相应余额
                requesterStorage.setRequesterBalance(_task, _taskCount, requesterStorage.getRequesterBalance(_task, _taskCount) - reward);
                //接包者Balance不改变，因为待会直接自动将钱打给接包者

                //修改状态、任务完成数量、挣钱总数
                if(userStorage.getUserState(workers[i]) == 4) {
                    userStorage.changeStateToOnline(workers[i]);
                    userStorage.addTaskAccepted(workers[i], _task, taskType );
                    userStorage.addWorkerEarn(workers[i], reward);
                }
            }
        }
    }

}