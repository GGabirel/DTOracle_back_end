// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

//存储当前众包每一次发布的的所有数据
contract TaskPerformStorage {

	mapping(address => mapping(uint8 => uint[])) public TasksToRewards;//接包者的报酬，和委员会顺序一致
	mapping(address => mapping(uint8 => int16 [])) public TasksToRightLabels;//合约正确答案

	//质量评估时需要的数据结构，每次用完都会删掉
	mapping(address => mapping(int => uint)) public TaskTolabelCount;
	mapping(address =>int16[]) public TaskTolabls;

/////////////////---------修改任务 执行阶段的  信息-------------------------/////////////

	//开始任务时的数据修改
	function setStartTask(address _task, uint8 _taskCount, uint16 _imageNumber, uint8 _workersNumber) external {
		//初始化正确标注数组
		for(uint16 j =0; j< _imageNumber; j++) {
			TasksToRightLabels[_task][_taskCount].push(-1);
		}
		//初始化报酬数组
		for(uint8 i = 0; i < _workersNumber; i++) {
			TasksToRewards[_task][_taskCount].push(0);
		}
	}

	//修改index位置的正确答案
	function setRightByIndex(address _task, uint8 _taskCount, uint16 _index, int16 _rightLabel) external {
		TasksToRightLabels[_task][_taskCount][_index] = _rightLabel;
	}

	//修改index接包者的奖励
	function setRewardsByIndex(address _task, uint8 _taskCount, uint8 _index, uint _rewards) external {
		TasksToRewards[_task][_taskCount][_index] = _rewards;
	}

/////////////////---------获取任务 执行阶段的  信息-------------------------/////////////

	//获取正确标注数组
	function getRightLabels(address _task, uint8 _taskCount) public view returns(int16[] memory) {
		return TasksToRightLabels[_task][_taskCount];
	}

	//获取标注奖励
	function getWorkersRewards(address _task, uint8 _taskCount) public view returns(uint[] memory) {
		return TasksToRewards[_task][_taskCount];
	}

	//获取index位置的正确标注
	function getRightLabelByIndex(address _task, uint8 _taskCount, uint16 _index) public view returns(int) {
		return TasksToRightLabels[_task][_taskCount][_index];
	}

	//获取index位置的 标注奖励
	function getWorkersRewardByIndex(address _task, uint8 _taskCount, uint8 _index) public view returns(uint) {
		return TasksToRewards[_task][_taskCount][_index];
	}
}