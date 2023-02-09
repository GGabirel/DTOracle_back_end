// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

import "../storage/TaskPrepareStorage.sol";
import "../storage/TaskCreatStorage.sol";
import "../storage/TaskWorkerStorage.sol";
import "../storage/TaskRequesterStorage.sol";
import "../storage/UserStorage.sol";

    /**
        本合约内容为准备 任务阶段相关函数的逻辑实现，包含:
            发包者：设置子任务ID(分配任务)、选人
            接包者：预报名、报名、接受、拒绝
     */

contract TaskPrepareImpl {

    TaskPrepareStorage public prepareStorage;
    TaskCreatStorage public creatStorage;
    TaskWorkerStorage public workerStorage;
    TaskRequesterStorage public requesterStorage;
    UserStorage public userStorage;

    constructor(UserStorage _userStorage, TaskWorkerStorage _workerStorage, TaskRequesterStorage _requesterStorage, TaskCreatStorage _creatStorage, TaskPrepareStorage _prepareStorage) {
        userStorage = _userStorage;
        workerStorage = _workerStorage;
        requesterStorage = _requesterStorage;
        prepareStorage =_prepareStorage;
        creatStorage = _creatStorage;
    }

    event LogWorkerSelected(address indexed _candidater,  address indexed _task, uint _time);

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

    function preEnrollTask(address _task, address _enroller, bytes32 _randomHash) external 
        checkTimeIn(creatStorage.getPreEnrollTimeEnd(_task)) 
        checkState(_task,1) 

    {
        //检测报名者状态
        require(userStorage.getUserState(_enroller) == 1,"Not Online");
        uint8 curTaskCount = creatStorage.TasksCur(_task);
        //TaskStorage:预提交信息
        prepareStorage.addEnrollRandomHash(_task, curTaskCount, _enroller, _randomHash);

        //UserStorage:任务报名次数+1(正式报名了才算)
    }

    function enrollTask(address _task, address _enroller, uint _random, uint _enrollFee) external 
        checkTimeOut(creatStorage.getPreEnrollTimeEnd(_task))
		checkTimeIn(creatStorage.getEnrollTimeEnd(_task))
        checkState(_task,1) 
    {
        //检测报名费(一段时间后才可以取回)
        uint enrollFee = creatStorage.getEnrollFee(_task);
        require(enrollFee == _enrollFee," Enroll Fee Wrong!");
        //检测报名者状态
        require(userStorage.getUserState(_enroller) == 1,"Not Online");

        //验证是否一致
        require(keccak256(abi.encodePacked(_random)) == prepareStorage.TasksToRandomHash(_task, creatStorage.TasksCur(_task),_enroller),"Not same");

        //添加报名数据
        prepareStorage.addEnrollRandom(_task, creatStorage.TasksCur(_task), _enroller, _random);

        //修改接包者信息
        workerStorage.addEnrollRandom(_task, creatStorage.TasksCur(_task), _enroller, _enrollFee);
        //UserStorage:任务报名次数+1

        uint8 _taskType = creatStorage.TasksToType(_task, creatStorage.TasksCur(_task)); 
        userStorage.addTaskEnrolled(_enroller, _task, _taskType);

    }

    //还是先放在报名期间，因为此时委员会人数固定了
    function setSubTaskArray(address _task, address _requester, uint8 _index, int16[] memory _subTaskId) external 
        checkRequester(_task, _requester) 
        checkState(_task,1)
		checkTimeIn(creatStorage.getEnrollTimeEnd(_task))                                 
    {
        uint8 workersMax;
        uint16 imageNumber;
        (workersMax,,,,imageNumber,) = creatStorage.TasksToNumber(_task,creatStorage.TasksCur(_task));
        
        // ID检查有效性
        require(_subTaskId.length == imageNumber,"_subTaskId.length error");
        for(uint i =0;i<_subTaskId.length ; i++)
            require(_subTaskId[i] == 0 || _subTaskId[i] == -1,"Id must be 0 or -1");
        
        require(_index < workersMax,"_index should < workersMax" );
        //设置Id
        prepareStorage.setSubTaskIdByIndex(_task, creatStorage.TasksCur(_task), _index, _subTaskId);

        _checkSubTaskSet(_task, workersMax, _index);
    }

    function _checkSubTaskSet(address _task, uint8 workersMax, uint8 _index) private {
        //检测是否都设置完
        uint8 counter = 0;
        for(uint8 i = 0 ;i < workersMax; i++) {
            if(prepareStorage.getSubTaskIdByIndex(_task, creatStorage.TasksCur(_task), _index).length > 0)
                counter++;
        }
        // 都设置完，设置标志位
        if(counter == workersMax) 
            requesterStorage.setSubTaskId(_task,creatStorage.TasksCur(_task));
    } 

    function sortition(address _task, address _requester) external
        checkRequester(_task, _requester) 
        checkTimeOut(creatStorage.getEnrollTimeEnd(_task))
		checkTimeIn(creatStorage.getSortitionEnd(_task))
    {
        //检测任务状态（不能用modifier,会导致栈太深）
        require(creatStorage.getTaskState(_task) == 1,"Task State is not Published");
        //检测报名人数
        uint8 taskCur = creatStorage.TasksCur(_task);
        address[] memory enrollers = prepareStorage.getEnrollPool(_task,taskCur);
        uint16 EnrollMin;
        uint8 WorkersMax;
        (WorkersMax,,,,,EnrollMin) = creatStorage.TasksToNumber(_task,taskCur);

        require(enrollers.length >= EnrollMin,"Enrollers too few" );

        //获得选人种子
        uint[] memory randomKeys = prepareStorage.getEnrollRandom(_task,taskCur);
        uint seed = 0;
        for(uint i =0 ;i < randomKeys.length; i++) {
            seed += randomKeys[i];
        }
        seed = uint(keccak256(abi.encodePacked(seed)));

        // 选人
        uint candidaterNumber = 0;
        while(candidaterNumber < WorkersMax) {
            address candidater = enrollers[seed % enrollers.length];
            if(userStorage.getUserState(candidater) == 1 && userStorage.getWorkerRep(candidater)> 0 && candidater != _requester) {
                //状态改变
                userStorage.changeStateToCandidate(candidater);
                //加入候选者池
                prepareStorage.addTaskToCandidaters(_task, taskCur, candidater);
                //候选者标志位改变
                workerStorage.addTaskToCandidaters(_task, taskCur, candidater);
                //触发选中事件
                emit LogWorkerSelected(candidater, _task, block.timestamp);
                candidaterNumber++;
            }

            seed = uint(keccak256(abi.encodePacked(seed)));
        }
    }

    function acceptTask(address _task, address _worker, uint _commFee) external 
        checkTimeOut(creatStorage.getSortitionEnd(_task))
		checkTimeIn(creatStorage.getAcceptTimeEnd(_task))
        checkState(_task,1) 
    {
        //检测承诺费(成功提交任务可以取回)
        require(creatStorage.getCommlFee(_task) == _commFee,"commFee Wrong");
        //检测是候选者、未接受任务
        bool selected;
        bool feedbacked;
        uint8 _taskCount = creatStorage.TasksCur(_task);
        (selected,feedbacked) = workerStorage.TasksToCandidaters(_task, _taskCount, _worker);
        require(selected,"Not Selected");
        require(!feedbacked,"Have Feedbacked");
        //接包者相应数量+1、状态变为Ready
        uint8 taskType = creatStorage.TasksToType(_task,_taskCount);
        userStorage.addTaskAccepted(_worker, _task, taskType );
        userStorage.changeStateToReady(_worker);
        //加入委员会
        prepareStorage.addCommittee(_task, _taskCount,_worker);
        uint8 index = prepareStorage.getCommitteeNumbers(_task, _taskCount) - 1;
        workerStorage.addCommittee(_task, _taskCount, _worker, _commFee, index);
        //初始化任务数组(不需要)
    }

    function rejectTask(address _task, address _worker) external 
        checkTimeOut(creatStorage.getSortitionEnd(_task))
		checkTimeIn(creatStorage.getAcceptTimeEnd(_task))
        checkState(_task,1) 
    {
        //检测是候选者、未接受任务
        bool selected;
        bool feedbacked;
        (selected,feedbacked) = workerStorage.TasksToCandidaters(_task,creatStorage.TasksCur(_task), _worker);
        require(selected,"Not Selected");
        require(!feedbacked,"Have Accepted");

        //扣一点信誉值，状态变为Online/Offline
        userStorage.subWorkerRep(_worker, 1);
        if(userStorage.getWorkerRep(_worker) >0 )
            userStorage.changeStateToOnline(_worker);
        else
            userStorage.changeStateToOffline(_worker);

        //接受标志位变为true
        workerStorage.setFeedbacked(_task, creatStorage.TasksCur(_task), _worker);
    }



    
}