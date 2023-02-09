// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

//存储众包正在进行中的那一次数据
contract TaskRequesterStorage {
    
	struct RequesterInfo {
		bool SubtaskId;
		bool Sortitioned;
		bool CheckAccepted;
		bool Started;
		bool CheckSubmited;
		bool Evaluated;
		bool Finished;
		uint Balance;
	}
	mapping(address => mapping(uint8 => RequesterInfo)) public TasksToRequester;


 
/////////////////---------修改 发包者  信息-------------------------/////////////

	//设置发包者状态位:检测 设置子任务
	function setSubTaskId(address _task, uint8 _taskCount)  external {
		TasksToRequester[_task][_taskCount].SubtaskId = true;
	}

	//设置发包者状态位:检测 选人
	function setSorttion(address _task, uint8 _taskCount)  external {
		TasksToRequester[_task][_taskCount].Sortitioned = true;
	}

	//设置发包者状态位:检测 候选者反馈
	function setCheckAccepted(address _task, uint8 _taskCount)  external {
		TasksToRequester[_task][_taskCount].CheckAccepted = true;
	}
	//设置发包者状态位:检测 开始任务
	function setStarted(address _task, uint8 _taskCount)  external {
		TasksToRequester[_task][_taskCount].Started = true;
	}

	//设置发包者状态位:检测 候选者提交
	function setCheckSubmited(address _task, uint8 _taskCount)  external {
		TasksToRequester[_task][_taskCount].CheckSubmited = true;
	}

	//设置发包者状态位:检测 质量评估
	function setEvaluated(address _task, uint8 _taskCount)  external {
		TasksToRequester[_task][_taskCount].Evaluated = true;
	}
	//设置发包者状态位:检测 完成任务
	function setFinished(address _task, uint8 _taskCount) external {
		TasksToRequester[_task][_taskCount].Finished= true;
	}

	//设置发包者余额:
	function setRequesterBalance(address _task, uint8 _taskCount, uint _newBalance)  external {
		TasksToRequester[_task][_taskCount].Balance = _newBalance;
	}

	//开始任务时的数据修改
	function setStartTask(address _task, uint8 _taskCount, uint _prePayment) external {
		//发包者余额
		TasksToRequester[_task][_taskCount].Balance += _prePayment;
		//设置开始标志位
		TasksToRequester[_task][_taskCount].Started = true;
	}

/////////////////---------读取 发包者  信息-------------------------/////////////

	//获得发包者 余额
	function getRequesterBalance(address _task, uint8 _taskCount) public view returns(uint) {
		return TasksToRequester[_task][_taskCount].Balance;
	}
	//获得发包者 设置子任务 标志位
	function getSubtaskId(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].SubtaskId;
	}
	//获得发包者 选人 标志位
	function getSortitioned(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].Sortitioned;
	}
	//获得发包者 检查接受 标志位
	function getCheckAccepted(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].CheckAccepted;
	}
	//获得发包者 开始任务 标志位
	function getStarted(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].Started;
	}
	//获得发包者 检查提交 标志位
	function getCheckSubmited(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].CheckSubmited;
	}
	//获得发包者 质量评估 标志位
	function getEvaluated(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].Evaluated;
	}
	//获得发包者 完成任务 标志位
	function getFinished(address _task, uint8 _taskCount) public view returns(bool) {
		return TasksToRequester[_task][_taskCount].Finished;
	}



}