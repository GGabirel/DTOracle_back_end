// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

//存储当前众包每一次发布的的所有数据
contract TaskWorkerStorage {

	struct EnrollerInfo {
		bool Enrolled;
		uint EnrollFee;//报名费,一定时间后可取，暂设为30天
		uint EnrollFeeBackTime;//可取回报名费的时间，用户不能设定，由平台决定
	}
    mapping(address => mapping(uint8 => mapping(address => EnrollerInfo))) public TasksToEnrollers;//接包者的信息


	struct CandidateInfo {
		bool Selected;
		bool Feedbacked;//是否反馈接受任务的标志位，true代表已反馈(接受拒绝都会true)
	}
    mapping(address => mapping(uint8 => mapping(address => CandidateInfo))) public TasksToCandidaters;//接包者的信息

	struct WorkerInfo {
		bool Accepted;//接受任务的标志
		bool PreSubmited;
		bool Submited;
		uint8 Index;//委员会中的序号
		uint16 RightCount;
		uint Balance;//包括承诺费+补偿奖励（标注奖励不在这里，质量评估时直接打给接包者）
		uint Random;
		bytes32 ResultHash;
		int16[] Result;
	}

    mapping(address => mapping(uint8 => mapping(address => WorkerInfo))) public TasksToWorkers;//接包者的信息


/////////////////---------读取 接包者 信息-------------------------/////////////
	//获取报名标志位
	function getEnrolled(address _task, uint8 _taskCount, address _enroller) public view returns(bool) {
		return TasksToEnrollers[_task][_taskCount][_enroller].Enrolled;
	}

	//读取提取报名费时间
	function getEnrollFeeBackTime(address _task, uint8 _taskCount, address _enroller) public view returns(uint) {
		return TasksToEnrollers[_task][_taskCount][_enroller].EnrollFeeBackTime;
	}

	//获取报名费
	function getEnrollFee(address _task, uint8 _taskCount, address _enroller) public view returns(uint) {
		return TasksToEnrollers[_task][_taskCount][_enroller].EnrollFee;
	}

	//获得接包者是否被任务 选中
	function getSelected(address _task, uint8 _taskCount, address _worker) public view returns(bool) {
		return TasksToCandidaters[_task][_taskCount][_worker].Selected;
	}
	//获得接包者是否 接受 任务 
	function getAccepted(address _task, uint8 _taskCount, address _worker) public view returns(bool) {
		return TasksToWorkers[_task][_taskCount][_worker].Accepted;
	}
	//获得接包者是否在当前任务 预提交
	function getPreSubmited(address _task, uint8 _taskCount, address _worker) public view returns(bool) {
		return TasksToWorkers[_task][_taskCount][_worker].PreSubmited;
	}
	//获得接包者是否在当前任务 提交
	function getSubmited(address _task, uint8 _taskCount, address _worker) public view returns(bool) {
		return TasksToWorkers[_task][_taskCount][_worker].Submited;
	}
	
	//获得接包者 在当前任务 余额
 	function getBalance(address _task, uint8 _taskCount, address _worker) public view returns(uint) {
		return TasksToWorkers[_task][_taskCount][_worker].Balance;
	}
	//获得接包者 在当前任务 正确标注数量
 	function getRightCount(address _task, uint8 _taskCount, address _worker) public view returns(uint16) {
		return TasksToWorkers[_task][_taskCount][_worker].RightCount;
	}
	
	//获取预提交承诺
	function getResultHash(address _task, uint8 _taskCount, address _worker) public view returns(bytes32) {
		return TasksToWorkers[_task][_taskCount][_worker].ResultHash;
	}

	//获取接包者index
	function getWorkerIndex(address _task, uint8 _taskCount, address _worker) public view returns(uint8) {
		return TasksToWorkers[_task][_taskCount][_worker].Index;
	}

	//获取接包者结果
	function getResult(address _task, uint8 _taskCount, address _worker) public view returns(int16[] memory) {
		return TasksToWorkers[_task][_taskCount][_worker].Result;
	}
	//获取接包者结果数组长度
	function getResultLength(address _task, uint8 _taskCount, address _worker) public view returns(uint) {
		return TasksToWorkers[_task][_taskCount][_worker].Result.length;
	}
	//获取接包者index位置的结果
	function getResultByIndex(address _task, uint8 _taskCount, address _worker, uint _index) public view returns(int16) {
		return TasksToWorkers[_task][_taskCount][_worker].Result[_index];
	}

/////////////////---------修改 接包者 信息-------------------------/////////////

	//增加提交信息
	function addEnrollRandom(address _task, uint8 _taskCount, address _enroller, uint _enrollFee) external {
		//禁止重复报名
		require(!TasksToEnrollers[_task][_taskCount][_enroller].Enrolled,"Have Enrolled;");
		//记录报名费提取时间(30天以后)
		TasksToEnrollers[_task][_taskCount][_enroller].EnrollFeeBackTime = block.timestamp + 30 days;
		//更改余额
		TasksToEnrollers[_task][_taskCount][_enroller].EnrollFee += _enrollFee;
		//更改报名标志位
		TasksToEnrollers[_task][_taskCount][_enroller].Enrolled = true;
	}

	//加入任务的候选者池
	function addTaskToCandidaters(address _task, uint8 _taskCount,  address _candidater) external  {
		TasksToCandidaters[_task][_taskCount][_candidater].Selected = true;
	}
	
	//加入委员会
	function addCommittee(address _task, uint8 _taskCount, address _worker, uint _commFee, uint8 _index) external  {
		//更改状态位
		TasksToCandidaters[_task][_taskCount][_worker].Feedbacked = true;
		TasksToWorkers[_task][_taskCount][_worker].Accepted = true;
		//修改工号
		TasksToWorkers[_task][_taskCount][_worker].Index = _index;
		//更改余额
		TasksToWorkers[_task][_taskCount][_worker].Balance += _commFee;
	}

	//修改候选者 任务接受标志
	function setFeedbacked(address _task, uint8 _taskCount, address _worker) external {
		TasksToCandidaters[_task][_taskCount][_worker].Feedbacked = true;
	}
	
	//修改预提交时的数据
	function presubmit(address _task, uint8 _taskCount,address _worker, bytes32 _commitment) external {
		//修改承诺信息
		TasksToWorkers[_task][_taskCount][_worker].ResultHash = _commitment;
		//修改预提交标志位
		TasksToWorkers[_task][_taskCount][_worker].PreSubmited = true;
	}

	//提交时的数据修改
	function submit(address _task, uint8 _taskCount,address _worker, int16[] memory _result) external {
		//修改结果信息
		TasksToWorkers[_task][_taskCount][_worker].Result = _result;
		//修改预提交标志位
		TasksToWorkers[_task][_taskCount][_worker].Submited = true;
	}

	//设置接包者余额
	function setWorkerBalance(address _task, uint8 _taskCount, address _worker, uint _newBalance) external {
		TasksToWorkers[_task][_taskCount][_worker].Balance = _newBalance;
	}
	//增加接包者余额
	function addWorkerBalance(address _task, uint8 _taskCount, address _worker, uint _value) external {
		TasksToWorkers[_task][_taskCount][_worker].Balance += _value;
	}

	//将报名费置为0
	function setEnrollFeeToZero(address _task, uint8 _taskCount, address _worker) external {
		TasksToEnrollers[_task][_taskCount][_worker].EnrollFee = 0;
	}

	//设置接包者正确标注个数
	function setRightCount(address _task, uint8 _taskCount, address _worker, uint16 _rightCount) external {
		TasksToWorkers[_task][_taskCount][_worker].RightCount = _rightCount;
	}

}