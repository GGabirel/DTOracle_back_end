//storage中的合约
const TaskCreatStorage = artifacts.require("TaskCreatStorage")
const TaskPerformStorage = artifacts.require("TaskPerformStorage")
const TaskPrepareStorage = artifacts.require("TaskPrepareStorage")
const TaskRequesterStorage = artifacts.require("TaskRequesterStorage")
const TaskWorkerStorage = artifacts.require("TaskWorkerStorage")
const UserStorage = artifacts.require("UserStorage")

//logic
const TaskCreatImpl = artifacts.require("TaskCreatImpl")
const TaskFinishImpl = artifacts.require("TaskFinishImpl")
const TaskPerformImpl = artifacts.require("TaskPerformImpl")
const TaskPrepareImpl = artifacts.require("TaskPrepareImpl")
const UserManagementImpl = artifacts.require("UserManagementImpl")

//view
const TaskCreatView = artifacts.require("TaskCreatView")
// const TaskFinishView = artifacts.require("TaskFinishView")
const TaskManagement = artifacts.require("TaskManagement")
// const TaskPerformView = artifacts.require("TaskPerformView")
const TaskPrepareView = artifacts.require("TaskPrepareView")
const UserManagement = artifacts.require("UserManagement")


module.exports = function(deployer) {
    //部署storage中的合约
    deployer.deploy(TaskCreatStorage);
    deployer.deploy(TaskPerformStorage);
    deployer.deploy(TaskPrepareStorage);
    deployer.deploy(TaskRequesterStorage);
    deployer.deploy(TaskWorkerStorage);
    deployer.deploy(UserStorage);
    
    //部署logic中的合约
    deployer.deploy(TaskCreatImpl, UserStorage.address, TaskCreatStorage.address);
    deployer.deploy(TaskPrepareImpl, UserStorage.address, TaskWorkerStorage.address, TaskRequesterStorage.address, TaskCreatStorage.address, TaskPrepareStorage.address);
    deployer.deploy(TaskPerformImpl, UserStorage.address, TaskWorkerStorage.address, TaskRequesterStorage.address, TaskCreatStorage.address, TaskPrepareStorage.address, TaskPerformStorage.address);
    deployer.deploy(TaskFinishImpl, UserStorage.address, TaskWorkerStorage.address, TaskRequesterStorage.address, TaskCreatStorage.address, TaskPrepareStorage.address, TaskPerformStorage.address);
    deployer.deploy(UserManagementImpl, UserStorage.address, TaskCreatImpl.address, TaskPrepareImpl.address, TaskPerformImpl.address, TaskFinishImpl.address);

    //部署view中的合约
    deployer.deploy(UserManagement,UserManagementImpl.address);
    
};