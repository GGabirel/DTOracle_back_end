// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;
import "../logic/UserManagementImpl.sol";

//用户管理界面的接口调用入口
contract UserManagement {
    
    UserManagementImpl umImpl;

    constructor(UserManagementImpl _umImpl) {
        umImpl = _umImpl;
    }
    uint registerFee = 1 wei;
    //注册费在这里交
    function register() public payable returns(bool success) {
        require(msg.value == registerFee,"registerFee wrong");
        require(umImpl.register(msg.sender, registerFee));
        return true;
    }

    function turnOn() public returns(bool success) {
        require(umImpl.turnOn(msg.sender));
        return true;
    }

    function turnOff() public returns(bool success) {
        require(umImpl.turnOff(msg.sender));
        return true;
    }
    function cancleAccount() public payable returns(bool success) {
        uint balance = umImpl.cancleAccount(msg.sender);
        payable(msg.sender).transfer(balance);

        return true;
    }

    function gennerateTS() public returns(address _newTask) {
        return umImpl.createTask(msg.sender);
    }
}

