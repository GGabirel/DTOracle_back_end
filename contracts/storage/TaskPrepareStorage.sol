// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

//存储当前众包每一次发布的的所有数据
contract TaskPrepareStorage {

	//报名需要的数据结构
	mapping(address => mapping(uint8 => address[])) public TasksToEnrollers;//合约的报名池
	mapping(address => mapping(uint8 => address[])) public TasksToCandidaters;//合约的候选者池
	mapping(address => mapping(uint8 => uint[])) public TasksToEnrollKey;//有必要存嘛？或者直接存一个(先存上)
	mapping(address => mapping(uint8 => mapping(address => bytes32))) public TasksToRandomHash;//报名者的随机数哈希
	mapping(address => mapping(uint8 => mapping(address => uint))) public TasksToRandom;//报名的随机数

	mapping(address => mapping(uint8 => address[])) public TasksCommittee;//合约的接包者委员会
	mapping(address => mapping(uint8 => mapping(uint8 => int16[]))) public TaskIdByIndex;//接包者的信息

/////////////////---------读取 准备阶段的  任务信息-------------------------/////////////
	
    //读取报名池
	function getEnrollPool(address _task, uint8 _taskCount) external view returns(address[] memory) {
		return TasksToEnrollers[_task][_taskCount];
	}

	//查看报名随机数
	function getEnrollRandom(address _task, uint8 _taskCount) external view returns(uint[] memory) {
		return TasksToEnrollKey[_task][_taskCount];
	}

	//读取候选者池
	function getTasksCandidaters(address _task, uint8 _taskCount) public view returns(address[] memory) {
		return TasksToCandidaters[_task][_taskCount];
	}

	//获得某次任务的委员会成员
	function getCommitteeAddrs(address _task, uint8 _taskCount) public view returns(address[] memory) {
		return TasksCommittee[_task][_taskCount];
	}
	//获得某次任务的委员会成员数量
	function getCommitteeNumbers(address _task, uint8 _taskCount) public view returns(uint8) {
		return uint8(TasksCommittee[_task][_taskCount].length);
	}

	//获得 当前任务 Index号接包者的 子任务ID
	function getSubTaskIdByIndex(address _task, uint8 _taskCount, uint8 _index) public view returns(int16[] memory) {
		return TaskIdByIndex[_task][_taskCount][_index];
	}

/////////////////---------修改 准备阶段的  任务信息-------------------------/////////////
	//增加预提交信息
	function addEnrollRandomHash(address _task, uint8 _taskCount, address _enroller, bytes32 _randomHash) external {
		TasksToRandomHash[_task][_taskCount][_enroller] = _randomHash;
	}

	//增加提交信息
	function addEnrollRandom(address _task, uint8 _taskCount, address _enroller, uint _random) external {
		//加入报名池
		TasksToEnrollers[_task][_taskCount].push(_enroller);
		//记录数据
		TasksToRandom[_task][_taskCount][_enroller] = _random;
		TasksToEnrollKey[_task][_taskCount].push(_random);//可删除

	}

	//加入任务的候选者池
	function addTaskToCandidaters(address _task, uint8 _taskCount,  address _candidater) external  {
		TasksToCandidaters[_task][_taskCount].push(_candidater);
	}
	
	//加入委员会
	function addCommittee(address _task, uint8 _taskCount, address _worker) external {
		//加入委员会
		TasksCommittee[_task][_taskCount].push(_worker);
	}
	
	//修改index的子任务ID
	function setSubTaskIdByIndex(address _task, uint8 _taskCount, uint8 _index, int16[] memory _subTaskId) external {
		TaskIdByIndex[_task][_taskCount][_index] = _subTaskId;
	}




}