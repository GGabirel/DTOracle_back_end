// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

import "../storage/UserStorage.sol";
import "../view/TaskManagement.sol";

//用户管理模块的逻辑实现
contract UserManagementImpl {
    UserStorage public userStorage;
    TaskCreatImpl public creatImpl;
    TaskPrepareImpl public prepareImpl;
    TaskPerformImpl public performImpl;
    TaskFinishImpl public finishImpl;


    constructor(UserStorage _userStorage, TaskCreatImpl _creatImpl, TaskPrepareImpl _prepareImpl, TaskPerformImpl _prerformImpl, TaskFinishImpl _finishImpl) {
        userStorage = _userStorage;
        creatImpl = _creatImpl;
        prepareImpl = _prepareImpl;
        performImpl = _prerformImpl;
        finishImpl = _finishImpl;
    }
    
	event LogTSContractGen(address indexed _requester, uint _time, address _newTask);

    function register(address _user,uint _registerFee) public returns(bool success) {
        userStorage.insertUser(_user, _registerFee);
        return true;
    }

    function turnOn(address _user) external returns(bool success) {
        userStorage.changeStateToOnline(_user);
        return true;
    }

    function turnOff(address _user) external returns(bool success) {
        userStorage.changeStateToOffline(_user);
        return true;
    }

    //注销账户会保留信誉值，清空余额和其他信息
    function cancleAccount(address _user) external returns(uint256 _balance) {
        //注销时状态必须为在线
        require(userStorage.getUserState(_user) == 1,"user state is not Online");
        //信誉值均大于10注销才可以退钱,
        if(userStorage.getRequesterRep(_user) >=10 || userStorage.getWorkerRep(_user) >=10) 
            _balance = 0;
        else
            _balance = userStorage.getBalance(_user);
        //注销账户信息
        userStorage.deleteUserInfo(_user);
        return _balance;
    }

    function createTask(address _requester) external returns(address _newTask) {
        //判断发包者信誉值大于10；
        require(userStorage.getRequesterRep(_requester) > 10,"Requester Rep too low");
  
        _newTask = address(new TaskManagement(creatImpl, prepareImpl, performImpl, finishImpl));

        //发包者增加合约创建信息
        userStorage.addTaskCreated(_requester, _newTask);

        //在taskStorage中初始化合约相关信息
        creatImpl.initTask(_newTask, _requester);
        //触发新合约生成事件
        emit LogTSContractGen(_requester, block.timestamp, _newTask);
        return _newTask;
    }
}

