// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

//存储当前众包每一次发布的的所有数据
contract TaskCreatStorage {

    enum TaskState {Fresh, Published, Submited, Completed, Failed, Stagnant}

	address[] public tasksAll;

	mapping(address =>address) public TaskToRequester;
	mapping(address => TaskState) public TaskToState;
	mapping(address => uint8) public TasksCur;
	mapping(address => uint8) public TasksNext;
	mapping(address => uint) public TaskIndex;
	mapping(address => mapping(uint8 => uint8)) public TasksToType;
	mapping(address => mapping(uint8 => TimeInfo)) public TasksToTime;
	mapping(address => mapping(uint8 => TimeEndInfo)) public TasksToTimeEnd;
	mapping(address => mapping(uint8 => NumberInfo)) public TasksToNumber;
	mapping(address => mapping(uint8 => FeeInfo)) public TasksToFee;
	mapping(address => mapping(uint8 => TextInfo)) public TasksToText;
	mapping(address => mapping(uint8 => Flag)) public TasksToFlag;

	struct TimeInfo{
		uint PreEnrollTime;
		uint EnrollTime;
		uint SortitionTime;
		uint AcceptTime;
		uint StartTime;
		uint PreSubmitTime;
		uint SubmitTime;
		uint EvaluateTime;
		uint WithdrawTime;
    }
    
    struct TimeEndInfo{
		uint  PreEnrollTimeEnd;
		uint  EnrollTimeEnd;
		uint  SortitionEnd;
		uint  AcceptTimeEnd;
		uint  StartTimeEnd;
		uint  PreSubmitTimeEnd;
		uint  SubmitTimeEnd;
		uint  EvaluateTimeEnd;
		uint  URWithdrawEnd;
		uint  UTWithdrawEnd;
	}

	struct NumberInfo {
		uint8 WorkerNumMax;
		uint8 WorkerNumMin;
		uint8 SubmitNum;
		uint8 TaskType;
		uint16 ImageNumber;
		uint16 EnrollNumberMin;
	}
	
	struct FeeInfo {
		uint Prepayment;
		uint ShareFee;
		uint RewardFee;
		uint EnrollFee;
		uint CommFee;
	}

	struct TextInfo {
		string Introduction;
		string Detail;
	}

	//众包任务的标志位
	struct Flag {
		bool setNumbers;
		bool setFee;
		bool setType;//众包类型可以不修改，默认为0
		bool setCreatTime;
		bool setPerformTime;
		bool published;
		bool setMissionID;
	}

	//生成新任务时初始化
	function initTask(address _newTask, address _requester) external {
		TaskToRequester[_newTask] = _requester;
		TaskToState[_newTask] = TaskState.Fresh;
		TasksNext[_newTask] = 1;
		TasksCur[_newTask] = 0;
		//把当前任务加入全体任务池，并分配index
		tasksAll.push(_newTask);
		TaskIndex[_newTask] = tasksAll.length - 1;
	}

//----------此下为修改数据的函数(只允许修改当前次数任务的数据)-------------------------------//

    
	//设置任务状态
	function setTaskState(address _task, uint8 _newState) external {
		TaskToState[_task] = TaskState(_newState);
	}

	//修改数量参数
    function setNumbers(address _task, uint16 _imageNumber, uint8 _workersMax, uint8 _worksersMin, uint16 _enrollerMin) external  
	{
		TasksToNumber[_task][TasksNext[_task]].ImageNumber =_imageNumber;
		TasksToNumber[_task][TasksNext[_task]].WorkerNumMax =_workersMax;
		TasksToNumber[_task][TasksNext[_task]].WorkerNumMin =_worksersMin;
		TasksToNumber[_task][TasksNext[_task]].EnrollNumberMin =_enrollerMin;
			
		TasksToFlag[_task][TasksNext[_task]].setNumbers = true;
    }
	//修改提交数量
	function setSubmitNumber(address _task, uint8 _submitNumber) external {
		TasksToNumber[_task][TasksNext[_task]].SubmitNum =_submitNumber;

	}
	
	//修改众包类型
	function setTaskType(address _task, uint8 _taskType)external    {
		TasksToType[_task][TasksNext[_task]] = _taskType;

		TasksToFlag[_task][TasksNext[_task]].setType = true;
	}
		
	//修改费用参数
    function setFee(address _task, uint _rewardFee, uint _enrollFee, uint _commFee) external    {
		uint oneUnit = 1 ether;

		TasksToFee[_task][TasksNext[_task]].RewardFee = _rewardFee  * oneUnit;
		TasksToFee[_task][TasksNext[_task]].EnrollFee = _enrollFee  * oneUnit;
		TasksToFee[_task][TasksNext[_task]].CommFee = _commFee  * oneUnit;

		TasksToFlag[_task][TasksNext[_task]].setFee = true;
    }

	//修改任务报名阶段的时间参数
	function setEnrollTime(address _task,  uint _preEnrollTime, uint _enrollTime) external   {
		uint oneUnit = 1 minutes;

		TasksToTime[_task][TasksNext[_task]].PreEnrollTime = _preEnrollTime * oneUnit;
		TasksToTime[_task][TasksNext[_task]].EnrollTime = _enrollTime * oneUnit;
		TasksToFlag[_task][TasksNext[_task]].setCreatTime = true;
	}

	//修改组建委员会阶段的时间参数
	function setCreatTime(address _task, uint _sortTime,uint _acceptTime, uint _startTime) external   {
		uint oneUnit = 1 minutes;

		TasksToTime[_task][TasksNext[_task]].SortitionTime = _sortTime * oneUnit;
		TasksToTime[_task][TasksNext[_task]].AcceptTime = _acceptTime * oneUnit;
		TasksToTime[_task][TasksNext[_task]].StartTime = _startTime *oneUnit;

		TasksToFlag[_task][TasksNext[_task]].setCreatTime = true;
	}

	//修改任务执行阶段的时间参数
	function setPerformTime(address _task, uint _presubmitTime, uint _submitTime, uint _evaluationTime, uint _withdrawTime) external   {
		uint oneUnit = 1 minutes;

		TasksToTime[_task][TasksNext[_task]].PreSubmitTime = _presubmitTime * oneUnit;
		TasksToTime[_task][TasksNext[_task]].SubmitTime = _submitTime * oneUnit;
		TasksToTime[_task][TasksNext[_task]].EvaluateTime = _evaluationTime * oneUnit;
		TasksToTime[_task][TasksNext[_task]].WithdrawTime = _withdrawTime * oneUnit;

		TasksToFlag[_task][TasksNext[_task]].setPerformTime = true;
	}

	//修改众包全过程的时间，发布任务时调用(理应放在CSImpl层)
	function publish(address _task, string memory _taskIntroduction) external   {
		TasksToText[_task][TasksNext[_task]].Introduction = _taskIntroduction;

        //检查已经修改好任务的基本信息
        require(TasksToFlag[_task][TasksNext[_task]].setNumbers, "Havn't Set Numbers");
        require(TasksToFlag[_task][TasksNext[_task]].setFee, "Havn't Set Fee");
        require(TasksToFlag[_task][TasksNext[_task]].setCreatTime, "Havn't Set CreatTime");
        require(TasksToFlag[_task][TasksNext[_task]].setPerformTime, "Havn't Set PerformTime");

		// require(TasksToFlag[_task][TasksNext[_task]].setType, "Havn't Set task Type");//众包类型可以不修改，默认为0

		TasksToTimeEnd[_task][TasksNext[_task]].PreEnrollTimeEnd = block.timestamp + TasksToTime[_task][TasksNext[_task]].EnrollTime;
		TasksToTimeEnd[_task][TasksNext[_task]].EnrollTimeEnd =TasksToTimeEnd[_task][TasksNext[_task]].PreEnrollTimeEnd + TasksToTime[_task][TasksNext[_task]].EnrollTime;
		TasksToTimeEnd[_task][TasksNext[_task]].SortitionEnd = TasksToTimeEnd[_task][TasksNext[_task]].EnrollTimeEnd + TasksToTime[_task][TasksNext[_task]].SortitionTime;
		TasksToTimeEnd[_task][TasksNext[_task]].AcceptTimeEnd = TasksToTimeEnd[_task][TasksNext[_task]].SortitionEnd + TasksToTime[_task][TasksNext[_task]].AcceptTime;
		TasksToTimeEnd[_task][TasksNext[_task]].StartTimeEnd = TasksToTimeEnd[_task][TasksNext[_task]].AcceptTimeEnd + TasksToTime[_task][TasksNext[_task]].StartTime;
		TasksToTimeEnd[_task][TasksNext[_task]].PreSubmitTimeEnd = TasksToTimeEnd[_task][TasksNext[_task]].StartTimeEnd + TasksToTime[_task][TasksNext[_task]].PreSubmitTime;
		TasksToTimeEnd[_task][TasksNext[_task]].SubmitTimeEnd = TasksToTimeEnd[_task][TasksNext[_task]].PreSubmitTimeEnd + TasksToTime[_task][TasksNext[_task]].SubmitTime;
		TasksToTimeEnd[_task][TasksNext[_task]].EvaluateTimeEnd = TasksToTimeEnd[_task][TasksNext[_task]].SubmitTimeEnd + TasksToTime[_task][TasksNext[_task]].EvaluateTime;
		TasksToTimeEnd[_task][TasksNext[_task]].URWithdrawEnd = TasksToTimeEnd[_task][TasksNext[_task]].EvaluateTimeEnd + TasksToTime[_task][TasksNext[_task]].WithdrawTime;
		TasksToTimeEnd[_task][TasksNext[_task]].UTWithdrawEnd = TasksToTimeEnd[_task][TasksNext[_task]].URWithdrawEnd + TasksToTime[_task][TasksNext[_task]].WithdrawTime;

		//计算发包者本次任务需支付的预付款
		TasksToFee[_task][TasksNext[_task]].Prepayment = TasksToFee[_task][TasksNext[_task]].RewardFee * TasksToNumber[_task][TasksNext[_task]].WorkerNumMax * TasksToNumber[_task][TasksNext[_task]].ImageNumber;
		//当前任务次数+1
		TasksCur[_task]++;
		//任务标志位
		TasksToFlag[_task][TasksNext[_task]].published = true;
		//任务状态改变
		TaskToState[_task] = TaskState.Published;
	}

	//开始任务时的数据修改
	function setStartTask(address _task, uint8 _taskCount, string memory _details) external {
		//修改任务详情文本
		TasksToText[_task][_taskCount].Detail = _details;
		//任务状态
		TaskToState[_task] = TaskState.Submited;
	}

//----------此下为 读取数据 的函数(允许读取修改指定次数任务的数据)-------------------------------//
	//读取任务状态
	function getTaskState(address _task) public view returns(uint8) {
		return uint8(TaskToState[_task]);
	}

	//获得 最低报名者 数量
	function getEnrollMin(address _task, uint8 _taskCount) public view returns(uint16) {
		return TasksToNumber[_task][_taskCount].EnrollNumberMin;
	}
	//获得 接包者最少 数量
	function getWorkersMin(address _task, uint8 _taskCount) public view returns(uint8) {
		return TasksToNumber[_task][_taskCount].WorkerNumMin;
	}
	//获得 接包者最多 数量
	function getWorkersMax(address _task, uint8 _taskCount) public view returns(uint8) {
		return TasksToNumber[_task][_taskCount].WorkerNumMax;
	}
	//获得 图片 数量
	function getImageNumber(address _task, uint8 _taskCount) public view returns(uint16) {
		return TasksToNumber[_task][_taskCount].ImageNumber;
	}

	//获取报名费用
	function getEnrollFee(address _task) public view returns(uint) {
		return TasksToFee[_task][TasksCur[_task]].EnrollFee;
	}
	//获取承诺费用
	function getCommlFee(address _task) public view returns(uint) {
		return TasksToFee[_task][TasksCur[_task]].CommFee;
	}
	//获取单个奖励
	function getRewardFeeCur(address _task) public view returns(uint) {
		return TasksToFee[_task][TasksCur[_task]].RewardFee;
	}
	//获取预付款项
	function getPrePaymentCur(address _task) public view returns(uint) {
		return TasksToFee[_task][TasksCur[_task]].Prepayment;
	}

	//根据地址和次数获取众包类型
	function getTaskTypeByCount(address _task, uint8 _taskCount) public view returns(uint8) {
		return TasksToType[_task][_taskCount];
	}

	//获取当前执行次数的众包类型
	function getTaskTypeByCur(address _task) public view returns(uint8) {
		return TasksToType[_task][TasksNext[_task]];
	}


	//获得当前任务的  预报名  时间
	function getPreEnrollTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].PreEnrollTime;
	}
	//获得当前任务的  报名  时间
	function getEnrollTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].EnrollTime;
	}
	//获得当前任务的  选人  时间
	function getSortitionTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].SortitionTime;
	}
	//获得当前任务的  接受反馈  时间
	function getAcceptTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].AcceptTime;
	}
	//获得当前任务的  任务开始  时间
	function getStartTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].StartTime;
	}
	//获得当前任务的 预提交 时间
	function getPreSubmittedTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].PreSubmitTime;
	}
	//获得当前任务 正式提交 时间
	function getSubmittedTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].SubmitTime;
	}
	//获得当前任务的 质量评估 时间
	function getEvaluateTime(address _task) public view returns(uint) {
		return TasksToTime[_task][TasksNext[_task]].EvaluateTime;
	}
	//获得当前任务的  预报名  截止时间
	function getPreEnrollTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].PreEnrollTimeEnd;
	}
	//获得当前任务的  报名  截止时间
	function getEnrollTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].EnrollTimeEnd;
	}
	//获得当前任务的  选人  截止时间
	function getSortitionEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].SortitionEnd;
	}
	//获得当前任务的  接受反馈  截止时间
	function getAcceptTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].AcceptTimeEnd;
	}
	//获得当前任务的  任务开始  截止时间
	function getStartTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].StartTimeEnd;
	}
	//获得当前任务的 预提交 截止时间
	function getPreSubmitTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].PreSubmitTimeEnd;
	}
	//获得当前任务 正式提交 截止时间
	function getSubmitTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].SubmitTimeEnd;
	}
	//获得当前任务的 质量评估 截止时间
	function getEvaluateTimeEnd(address _task) public view returns(uint) {
		return TasksToTimeEnd[_task][TasksNext[_task]].EvaluateTimeEnd;
	}

}