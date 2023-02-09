// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;


import "../logic/TaskCreatImpl.sol";

contract TaskCreatView {
	address public requester;
    TaskCreatImpl public creatImpl;
    address public task;
    constructor(address _requester, TaskCreatImpl _creatImpl) {
        requester = _requester;
        creatImpl = _creatImpl;
        task = address(this);
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

        creatImpl.setFee(task, msg.sender, _rewardFee, _enrollFee, _comFee);

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


}