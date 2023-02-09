// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;


import "../storage/TaskCreatStorage.sol";
import "../storage/TaskWorkerStorage.sol";
import "../storage/TaskRequesterStorage.sol";
import "../storage/UserStorage.sol";

    /**
        本合约内容为创建任务阶段相关函数的逻辑实现，包含:
            设置各种参数信息、发布任务
     */

contract TaskCreatImpl {

    TaskCreatStorage public creatStorage;
    UserStorage public userStorage;

    constructor(UserStorage _userStorage, TaskCreatStorage _creatStorage) {
        userStorage = _userStorage;
        
        creatStorage =_creatStorage;
    }

	event LogTaskStateModified(address indexed _task, address indexed _who, uint _time, uint8 _newstate);


    modifier checkRequester(address _task ,address _requester) {
		require(creatStorage.TaskToRequester(_task) == _requester,"Not requester");
		_;
	}

	modifier checkState(address _task, uint8 _state) {
		require(creatStorage.getTaskState(_task) == _state,"Wrong State");
		_;
	}

    function initTask(address _newTask, address _requester) external {
        creatStorage.initTask(_newTask, _requester);
    }

    function setNumbers(address _task, address _requester, uint16 _imageNumber, uint8 _workersMax, uint8 _worksersMin, uint16 _enrollerMin) external 
        checkRequester(_task, _requester) 
        checkState(_task,0) 
    {
        creatStorage.setNumbers(_task,_imageNumber, _workersMax, _worksersMin, _enrollerMin);
    }

    function setFee(address _task,address _requester, uint _rewardFee, uint _enrollFee, uint _comFee) external 
        checkRequester(_task, _requester) 
        checkState(_task,0)
    {
		
        creatStorage.setFee(_task, _rewardFee, _enrollFee, _comFee);
    }

    //任务类型暂且设为三种，默认(不设置)为0
	function setTaskType(address _task,address _requester, uint8 _taskType)external 
        checkRequester(_task, _requester)
        checkState(_task,0) 
    {
		
        creatStorage.setTaskType(_task, _taskType);
	}

	function setCreatTime(address _task, address _requester, uint _preEnrollTime, uint _enrollTime, uint _sortTime,uint _acceptTime, uint _startTime) external 
        checkRequester(_task, _requester)
        checkState(_task,0) 
    {
        creatStorage.setEnrollTime(_task, _preEnrollTime, _enrollTime);
        creatStorage.setCreatTime(_task, _sortTime, _acceptTime, _startTime);
	}

	function setPerformTime(address _task, address _requester, uint _presubmitTime, uint _submitTime, uint _evaluationTime, uint _withdrawTime) external         
        checkRequester(_task, _requester)
        checkState(_task,0) 
    {
        creatStorage.setPerformTime(_task, _presubmitTime, _submitTime, _evaluationTime, _withdrawTime);
    }

    function publishTask(address _task, address _requester, string memory _taskIntroduction) external 
        checkRequester(_task, _requester) 
        checkState(_task,0) 
    {
        
        //TaskStorage:各种时间信息
        creatStorage.publish(_task, _taskIntroduction);
        
        //UserStorage:任务发布次数+1
        uint8 _taskType = creatStorage.TasksToType(_task, creatStorage.TasksCur(_task)); 
        userStorage.addTaskPublished(_requester, _task, _taskType);

		emit LogTaskStateModified(_task, _requester, block.timestamp, 1);

    }
}