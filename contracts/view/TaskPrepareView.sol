// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;


import "../logic/TaskPrepareImpl.sol";

contract TaskPrepareView {
	address public requester;
    TaskPrepareImpl public prepareImpl;
    address public task;
    constructor(address _requester,address _task, TaskPrepareImpl _prepareImpl) {
        requester = _requester;
        prepareImpl = _prepareImpl;
        task = _task;
    }

    function preEnroll(bytes32 _randomHash) public {
        prepareImpl.preEnrollTask(task, msg.sender, _randomHash);
    }

    function enroll(uint _random) public payable {
        prepareImpl.enrollTask(task, msg.sender, _random, msg.value);
    }

    //这里做了一个隐式转换，需要在int后面加上16
    function setSubtaskId(uint8 _index, int16[] memory _subTaskId) public {
        prepareImpl.setSubTaskArray(task, msg.sender, _index, _subTaskId);
    }

    function sortition() public {
        prepareImpl.sortition(task, msg.sender);
    }

    function acceptTask() public payable {
        prepareImpl.acceptTask(task, msg.sender, msg.value);
    }

    function rejectTask() public  {
        prepareImpl.rejectTask(task, msg.sender);    
    }


}