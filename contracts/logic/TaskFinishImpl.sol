// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

import "../storage/TaskPerformStorage.sol";
import "../storage/TaskPrepareStorage.sol";
import "../storage/TaskCreatStorage.sol";
import "../storage/TaskWorkerStorage.sol";
import "../storage/TaskRequesterStorage.sol";
import "../storage/UserStorage.sol";

    /**
        本合约内容为结束任务阶段相关函数的逻辑实现，包含:
            发包者取款、结束任务；、重启任务（暂不实现）
            接包者的检测函数、接包者取款、报名者取回报名费；发包者离开委员会(无需离开)
     */

contract TaskFinishImpl {

    // TaskFinishStorage public finishStorage;
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

	event LogTaskStateModified(address indexed _task, address indexed _who, uint _time, uint8 _newstate);

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

    function requesterWithdraw(address _task, address _requester) external
        checkRequester(_task, _requester)
        checkTimeOut(creatStorage.getEvaluateTimeEnd(_task))
        returns(uint) 
    {   
        /**
            检测条件：
            角色：requester
            时间：> evaluateEnd
            任务状态：Completed  3 || Failed 4
            余额： ！= 0
         */
        require(creatStorage.getTaskState(_task) == 3 || creatStorage.getTaskState(_task) == 4,"Wrong State");
        
        uint8 _taskCount = creatStorage.TasksCur(_task);
        uint balance = requesterStorage.getRequesterBalance(_task, _taskCount);
        require(balance != 0,"Have no Money");

        requesterStorage.setRequesterBalance(_task, _taskCount, 0);
        return balance;
    }

    function workerWithdraw(address _task, address _worker) external
        checkTimeOut(creatStorage.getEvaluateTimeEnd(_task))
        returns(uint) 
    {   
        /**
            检测条件：
            角色：worker
            时间：> evaluateEnd
            任务状态：Completed  3 || Stagant 5
            余额： ！= 0
         */
        require(creatStorage.getTaskState(_task) == 3 || creatStorage.getTaskState(_task) == 5,"Wrong State");

        uint8 _taskCount = creatStorage.TasksCur(_task);
        uint balance = workerStorage.getBalance(_task, _taskCount, _worker);
        require(balance != 0,"Have no Money");

        workerStorage.setWorkerBalance(_task, _taskCount, _worker, 0);
        return balance;    
    }

    function finishTask(address _task, address _requester) external
        checkRequester(_task, _requester)
        checkTimeOut(creatStorage.getEvaluateTimeEnd(_task))
        returns(uint, address[] memory, uint[] memory)
    {
        require(creatStorage.getTaskState(_task) == 3 || creatStorage.getTaskState(_task) == 4,"Wrong State");

        //把剩余的钱退给发包者
        //帮忙检查接包者有无未取的存款：质量评估时把奖励退回，此时未取的存款为承诺费
        uint8 _taskCount = creatStorage.TasksCur(_task);
        
        address[] memory workers = prepareStorage.getCommitteeAddrs(_task, _taskCount);
        uint[] memory balances = new uint[](workers.length); 
       
        for(uint8 i = 0; i < workers.length; i++) {
            balances[i] = workerStorage.getBalance(_task, _taskCount, workers[i]);
        }
        //如果自己还有钱没取，一并取了
        uint requesterBalance = requesterStorage.getRequesterBalance(_task, _taskCount);

        //发包者对应熟练度增加
        uint8 taskType = creatStorage.TasksToType(_task, _taskCount);
        userStorage.addTaskFinished(_requester, _task, taskType);

        //修改任务状态:为Fresh 0
        creatStorage.setTaskState(_task, 0);
        emit LogTaskStateModified(_task, _requester, block.timestamp, 0);
        
        return(requesterBalance, workers, balances);
    }

    function withdrawEnrollFee(address _task, address _enroller) external returns(uint) {
        uint8 _taskCount = creatStorage.TasksCur(_task);
        //判断是否报名
        require(workerStorage.getEnrolled(_task, _taskCount, _enroller),"HaveNot Enrolled");
        //判断超出报名费冷却时间
        require(block.timestamp > workerStorage.getEnrollFeeBackTime(_task, _taskCount, _enroller),"Too early");
        //判断还有报名费
        uint enrollFee = workerStorage.getEnrollFee(_task, _taskCount, _enroller);
        require(enrollFee != 0, "No EnrollFee");
        
        //修改报名费余额
        workerStorage.setEnrollFeeToZero(_task, _taskCount, _enroller);

        return enrollFee;
    }

    //检测设置众包数组和选人，处罚信誉值：R-1;R-2，将报名费赔偿给调用者
    function checkSort(address _task, address _enroller) external 
        checkTimeOut(creatStorage.getSortitionEnd(_task))
        checkState(_task,1)
    {
        //判断是报名者
        uint8 _taskCount = creatStorage.TasksCur(_task);
        require(workerStorage.getEnrolled(_task, _taskCount, _enroller), "HaveNot Enrolled");

        //判断是否设置任务或者选人
        if(!requesterStorage.getSubtaskId(_task, _taskCount) || !requesterStorage.getSortitioned(_task, _taskCount)) {
            //降低1点信誉值
            userStorage.subRequesterRep(creatStorage.TaskToRequester(_task), 1);
            //扣除报名费补偿给调用者
            uint balance = requesterStorage.getRequesterBalance(_task, _taskCount);
            requesterStorage.setRequesterBalance(_task, _taskCount, 0);
            workerStorage.setWorkerBalance(_task, _taskCount, _enroller, workerStorage.getBalance(_task, _taskCount, _enroller) + balance);

            //修改任务状态
            creatStorage.setTaskState(_task, 5);
            emit LogTaskStateModified(_task, _enroller, block.timestamp, 5);
        }
    }

    function checkStart(address _task, address _candidater) external
        checkTimeOut(creatStorage.getStartTimeEnd(_task))
        checkState(_task,1)
    {
        //判断是报名者
        uint8 _taskCount = creatStorage.TasksCur(_task);
        require(workerStorage.getSelected(_task, _taskCount, _candidater), "HaveNot Selected");

        //判断是否设置任务或者选人
        if(!requesterStorage.getStarted(_task, _taskCount)) {
            //降低5点信誉值
            userStorage.subRequesterRep(creatStorage.TaskToRequester(_task), 5);
            //扣除报名费补偿给调用者
            uint balance = requesterStorage.getRequesterBalance(_task, _taskCount);
            requesterStorage.setRequesterBalance(_task, _taskCount, 0);
            workerStorage.addWorkerBalance(_task, _taskCount, _candidater, balance);

            //修改任务状态
            creatStorage.setTaskState(_task, 5);
            emit LogTaskStateModified(_task, _candidater, block.timestamp, 5);
        }
    }

	/**
		1.调用时间：质量评估窗口之后
		2.返回值：R应降低的信誉值
		3.调用时合约状态：Ready:未开始任务；Submited(没人调用)；Stagnanted(已经有接包者检测过)
		逻辑：判断应扣声誉值，计算补偿费用
		注意：该函数主要检测众包任务开始之后发包者的慵懒行为，没有考虑发包者没选人的情况，
		可以独立一个函数检测对发包者未选人进行处罚
	 */
    function checkEvaluated(address _task, address _worker) external
        checkTimeOut(creatStorage.getEvaluateTimeEnd(_task))
        checkState(_task,2)
    {
        //判断是报名者
        uint8 _taskCount = creatStorage.TasksCur(_task);
        require(workerStorage.getAccepted(_task, _taskCount, _worker), "Not Workers");

        if(!requesterStorage.getEvaluated(_task, _taskCount)) {
            //降低10点信誉值
            userStorage.subRequesterRep(creatStorage.TaskToRequester(_task), 5);
            
            //扣除预付款及报名费补偿给提交结果的接包者
            uint balance = requesterStorage.getRequesterBalance(_task, _taskCount);
            requesterStorage.setRequesterBalance(_task, _taskCount, 0);

            address[] memory workers = prepareStorage.getCommitteeAddrs(_task, _taskCount);

            uint submitCount;
            for(uint8 i = 0; i< workers.length; i++) {
                if(workerStorage.getPreSubmited(_task, _taskCount, workers[i])) {
                    submitCount++;
                }
            }

            uint shareFee = balance / submitCount;

            for(uint8 i = 0; i <workers.length; i++) {
                if(workerStorage.getPreSubmited(_task, _taskCount, workers[i])) {
                    workerStorage.addWorkerBalance(_task, _taskCount, workers[i], shareFee);
                }
            }

            //修改任务状态
            creatStorage.setTaskState(_task, 5);
            emit LogTaskStateModified(_task, _worker, block.timestamp, 5);
        }

    }


}