// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0;

contract UserStorage {
    
    enum UserState {Offline, Online, Candidate, Ready, Busy}
    //在入口合约设置、检查
    // uint256 registerFee = 1 ether;
    
    struct User {
        bool registered;//注册
        uint256 index;//序号
        uint256 registerFee;//注册费
        uint256 balance;//用户余额
        UserState state;//状态
    }
    
    mapping (address => User) public user;
    address payable[] public userAddr;
    
    struct Worker {
        uint8 reputation;
        uint256 taskEarn;//记录挣钱总数
		uint8[3] taskEnrolled;//接包者参与的众包任务数量
		uint8[3] taskAccepted;//接包者参与的众包任务数量
		uint8[3] taskCompleted;//接包者完成的众包任务数量
        address[] enrolledTasks;//报名过的
        address[] acceptedTasks;//参加过的
        address[] completedTasks;//完成过的
        // mapping(address => WorkerTaskInfo) taskInfo;

    }
    mapping (address => Worker) public worker;


    struct Requester {
        uint8 reputation;    
		uint8 taskCreated;//发包者创建的众包任务数量(不分类型)		
		uint8[3] taskPublished;//发包者发布的众包任务数量		
		uint8[3] taskFinished;//发包者完成的众包任务数量
        address[] createdTasks;
        address[] publishedTasks;
        address[] finishedTasks;
    }
    mapping (address => Requester) public requester;

    modifier checkRegister(address _normalAddr) {
        require(!user[_normalAddr].registered,"have Registered");
        _;
    }
    
    modifier checkIsUser(address _normalAddr) {
        require(user[_normalAddr].registered, "Not Registered");
        _;
    }

    //基本更改都在这里实现
//--------------------------------------查询函数--------------------------------------//


    //获取拥有的所有众包地址
    function getTaskCreatedAddrs(address _requester) public view checkIsUser(_requester) returns(address[] memory) {
        return requester[_requester].createdTasks;
    }

    //获取当前状态,uint8
    function getUserState(address _user) public view checkIsUser(_user) returns(uint8) {
        return uint8(user[_user].state);
    }

    //获取R_r
    function getRequesterRep(address _requester) public view checkIsUser(_requester) returns(uint8) {
        return requester[_requester].reputation;
    }
    //获取R_w
    function getWorkerRep(address _worker) public view checkIsUser(_worker) returns(uint8) {
        return worker[_worker].reputation;
    }
    //更改状态
    function changeUserState(address _user, UserState _newState) external checkIsUser(_user) {
        user[_user].state = _newState;
    }

    //获取用户余额
    function getBalance(address _user) public view checkIsUser(_user) returns(uint256 _balance) {
        return user[_user].balance;
    }

    //获取任务 创建 数量
    function getTaskCreated(address _requester) public view checkIsUser(_requester) returns(uint8) {
        return requester[_requester].taskCreated;
    }

    //获取某类型任务的 发布 数量
    function getTaskPublishedType(address _requester, uint8 _taskType) public view checkIsUser(_requester) returns(uint8) {
        return requester[_requester].taskPublished[_taskType];
    }
    //获取某类型任务的 报名 数量
    function getTaskEnrolledType(address _worker, uint8 _taskType) public view checkIsUser(_worker) returns(uint8) {
        return worker[_worker].taskEnrolled[_taskType];
    }

    //获取某类型任务的 接受 数量
    function getTaskJoinedType(address _worker, uint8 _taskType) public view checkIsUser(_worker) returns(uint8) {
        return worker[_worker].taskAccepted[_taskType];
    }

    //获取所有类型任务的 发布 数量
    function getTaskPublishedAll(address _requester) public view checkIsUser(_requester) returns(uint8[3] memory) {
        return requester[_requester].taskPublished;
    }

//--------------------------------------修改函数--------------------------------------//

    //增加用户信息
    function insertUser(address _user, uint _registerFee) external {
        require(!user[_user].registered,"have Registered");

        //增加用户基本信息
        userAddr.push(payable(_user));
        user[_user].registered = true;
        user[_user].index = userAddr.length - 1;
        
        user[_user].registerFee = _registerFee;
        user[_user].balance += _registerFee;
        user[_user].state = UserState.Online;

        //增加发包者基本信息
        requester[_user].reputation = 100;
        //增加接包者基本信息
        worker[_user].reputation = 100;
    }
    
    //删除用户信息:只保留信誉值，清空其他
    function deleteUserInfo(address _user) external checkIsUser(_user) {
        uint8 workerRep = worker[_user].reputation;
        uint8 requesterRep = requester[_user].reputation;
        delete user[_user];
        delete worker[_user];
        delete requester[_user];

        //保留信誉信息
        requester[_user].reputation = requesterRep;
        worker[_user].reputation = workerRep;
    }


    //增加用户余额
    function addBalance(address _user, uint _value) external checkIsUser(_user) {
        user[_user].balance += _value;
    }
    //减少用户余额
    function subBalance(address _user, uint _value) external checkIsUser(_user) {
        require(user[_user].balance >= _value, "balance is not enough");
        user[_user].balance -= _value;
    }

    //更改状态为Online
    function changeStateToOnline(address _user) external checkIsUser(_user){
        require(worker[_user].reputation > 0 || requester[_user].reputation > 0,"reputation = 0");
        user[_user].state = UserState.Online;
    }

    //更改状态为Offline
    function changeStateToOffline(address _user) external checkIsUser(_user){
        user[_user].state = UserState.Offline;
    }

    //更改状态为Candidate
    function changeStateToCandidate(address _user) external checkIsUser(_user){
        require(user[_user].state == UserState.Online,"Not Online");
        user[_user].state = UserState.Candidate;
    }
    
    //更改状态为Ready
    function changeStateToReady(address _user) external checkIsUser(_user){
        require(user[_user].state == UserState.Candidate,"Not Candidater");
        user[_user].state = UserState.Ready;
    }

    //更改状态为Busy
    function changeStateToBusy(address _user) external checkIsUser(_user){
        require(user[_user].state == UserState.Ready,"Not Ready");
        user[_user].state = UserState.Busy;
    }

    //减R_r
    function subRequesterRep(address _requester, uint8 _value) external returns(uint8){
        if(requester[_requester].reputation > _value)
            requester[_requester].reputation -= _value;
        else
            requester[_requester].reputation -= 0;

        return requester[_requester].reputation;
    }

    //减R_w
    function subWorkerRep(address _worker, uint8 _value) external  returns(uint8){
        if(worker[_worker].reputation > _value)
            worker[_worker].reputation -= _value;
        else
            worker[_worker].reputation -= 0;

        return worker[_worker].reputation;
    }

    //增加接包者 挣钱总量
    function addWorkerEarn(address _worker, uint _value) external {
        worker[_worker].taskEarn += _value;
    }

    //增加任务 创建 数量
    function addTaskCreated(address _requester, address _newTask) external {
        requester[_requester].taskCreated++;
        requester[_requester].createdTasks.push(_newTask);
    }
    //增加某类型任务的 发布 数量
    function addTaskPublished(address _requester, address _task, uint8 _taskType) external  checkIsUser(_requester) {
        requester[_requester].taskPublished[_taskType]++;
        requester[_requester].publishedTasks.push(_task);
    }

    //增加某类型任务的 完成 数量
    function addTaskFinished(address _requester, address _task, uint8 _taskType) external  checkIsUser(_requester) {
        requester[_requester].taskFinished[_taskType]++;
        requester[_requester].finishedTasks.push(_task);
    }

    //增加某类型任务的 报名 数量
    function addTaskEnrolled(address _worker, address _task, uint8 _taskType) external  checkIsUser(_worker) {
        worker[_worker].taskEnrolled[_taskType]++;
        worker[_worker].enrolledTasks.push(_task);
    }

    //增加某类型任务的 接受 数量
    function addTaskAccepted(address _worker, address _task, uint8 _taskType) external  checkIsUser(_worker) {
        worker[_worker].taskAccepted[_taskType]++;
        worker[_worker].acceptedTasks.push(_task);
    }

    //增加某类型任务的 成功参与 数量
    function addTaskCompleted(address _worker, address _task, uint8 _taskType) external  checkIsUser(_worker) {
        worker[_worker].taskCompleted[_taskType]++;
        worker[_worker].completedTasks.push(_task);
    }
}