// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

// import "../logic/UserManagementImpl.sol";
import "../logic/TaskCreatImpl.sol";
import "../logic/TaskPrepareImpl.sol";
import "../logic/TaskPerformImpl.sol";
import "../logic/TaskFinishImpl.sol";

contract TaskManagement {
    
    TaskCreatImpl public creatImpl;
    TaskPrepareImpl public prepareImpl;
    TaskPerformImpl public performImpl;
    TaskFinishImpl public finishImpl;


    constructor(TaskCreatImpl _creatImpl, TaskPrepareImpl _prepareImpl, TaskPerformImpl _prerformImpl, TaskFinishImpl _finishImpl) {
        creatImpl = _creatImpl;
        prepareImpl = _prepareImpl;
        performImpl = _prerformImpl;
        finishImpl = _finishImpl;
    }
    
    //输入数据合格检查放在view层
    function setNumbers(uint16 _imageNumber, uint8 _workersMax, uint8 _worksersMin, uint16 _enrollerMin) public {
        require(_imageNumber > 0,"_imageNumber cann't be 0");
        require(_workersMax > 0,"_workersMax cann't be 0");
        require(_worksersMin > 0,"_worksersMin cann't be 0");
        require(_enrollerMin > _worksersMin,"_enrollerMin cann't < _worksersMin");

        creatImpl.setNumbers(address(this), msg.sender, _imageNumber, _workersMax, _worksersMin, _enrollerMin);
    }

    function setFee( uint _rewardFee, uint _enrollFee, uint _comFee) public {
		//设计三种押金都不能为0
        require(_rewardFee > 0,"_rewardFee cann't be 0");
        require(_enrollFee > 0,"_enrollFee cann't be 0");
        require(_comFee > 0,"_comFee cann't be 0");

        creatImpl.setFee(address(this), msg.sender, _rewardFee, _enrollFee, _comFee);

    }

	function setTaskType( uint8 _taskType)external   {
        //三种众包任务0，1，2，默认为0
        require(_taskType >=0 && _taskType <=3,"0<= _taskType <=2");
        creatImpl.setTaskType(address(this), msg.sender, _taskType);
	}

	function setCreatTime( uint _preEnrollTime, uint _enrollTime, uint _sortTime,uint _acceptTime, uint _startTime) external  {
        require(_preEnrollTime > 0,"_preEnrollTime cann't be 0");
        require(_enrollTime > 0,"_enrollTime cann't be 0");
        require(_sortTime > 0,"_sortTime cann't be 0");
        require(_acceptTime > 0,"_acceptTime cann't be 0");
        require(_startTime > 0,"_startTime cann't be 0");

        creatImpl.setCreatTime(address(this), msg.sender, _preEnrollTime, _enrollTime, _sortTime, _acceptTime, _startTime);
	}

	function setPerformTime( uint _presubmitTime, uint _submitTime, uint _evaluationTime, uint _withdrawTime) external  {
        require(_presubmitTime > 0,"_presubmitTime cann't be 0");
        require(_submitTime > 0,"_submitTime cann't be 0");
        require(_evaluationTime > 0,"_evaluationTime cann't be 0");
        require(_withdrawTime > 0,"_withdrawTime cann't be 0");

        creatImpl.setPerformTime(address(this), msg.sender, _presubmitTime, _submitTime, _evaluationTime, _withdrawTime);
	}

    function publishTask(string memory _taskIntroduction) public {
        creatImpl.publishTask(address(this), msg.sender, _taskIntroduction);
    }

    function preEnroll(bytes32 _randomHash) public {
        prepareImpl.preEnrollTask(address(this), msg.sender, _randomHash);
    }

    function enroll(uint _random) public payable {
        prepareImpl.enrollTask(address(this), msg.sender, _random, msg.value);
    }

    function setSubtaskId(uint8 _index, int16[] memory _subTaskId) public {
        prepareImpl.setSubTaskArray(address(this), msg.sender, _index, _subTaskId);
    }

    function sortition() public {
        prepareImpl.sortition(address(this), msg.sender);
    }

    function acceptTask() public payable {
        prepareImpl.acceptTask(address(this), msg.sender, msg.value);
    }

    function rejectTask() public  {
        prepareImpl.rejectTask(address(this), msg.sender);    
    }


    function checkAccepted() public {
        performImpl.checkAccept(address(this), msg.sender);
    }
    function startTask(string memory _details) public payable {
        performImpl.startTask(address(this), msg.sender, _details, msg.value);
    }

    function preSubmit(bytes32 _commitment) public {
        performImpl.preSubmit(address(this), msg.sender, _commitment);
    }

    function submitResult(int16[] memory _result, uint _random) public {
        performImpl.submit(address(this), msg.sender, _result, _random);
    }
    
    function checkSubmit() public {
        performImpl.checkSubmit(address(this), msg.sender);
    }
    
    function evaluate() public payable {
        address[] memory workers;
        uint[] memory rewards;
        (workers, rewards) = performImpl.evaluate(address(this), msg.sender);

        //挨个退钱
        for(uint8 i =0; i< workers.length; i++) {
            if(rewards[i] !=0)
                payable(workers[i]).transfer(rewards[i]);
        }
    }

    function requesterWithdraw() public payable {
        uint balance = finishImpl.requesterWithdraw(address(this), msg.sender);
        payable(msg.sender).transfer(balance);
    }
    function workerWithdraw() public payable {
        uint balance = finishImpl.workerWithdraw(address(this), msg.sender);
        payable(msg.sender).transfer(balance);
    }

    function finishTask() public payable {
        address[] memory workers;
        uint[] memory workerBalances;
        uint requesterBalance;

        (requesterBalance, workers, workerBalances) = finishImpl.finishTask(address(this), msg.sender);

        if(requesterBalance != 0) {
            payable(msg.sender).transfer(requesterBalance);
        }

        for(uint8 i = 0; i< workers.length; i++) {
            if(workerBalances[i] != 0) {
                payable(workers[i]).transfer(workerBalances[i]);
            }
        }

    }

    function withdrawEnrollFee() public payable {
        uint enrollFee = finishImpl.withdrawEnrollFee(address(this), msg.sender);
        payable(msg.sender).transfer(enrollFee);
    }

    function checkSortition() public {
        finishImpl.checkSort(address(this), msg.sender);
    }

    function checkStart() public {
        finishImpl.checkStart(address(this), msg.sender);
    }

    function checkEvaluate() public {
        finishImpl.checkEvaluated(address(this), msg.sender);
    }
}