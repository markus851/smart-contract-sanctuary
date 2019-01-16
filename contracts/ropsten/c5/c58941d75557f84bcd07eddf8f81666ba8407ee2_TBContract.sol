pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        
        require(newOwner != address(0));
        owner = newOwner;
    }
}



/**
  TBProject holds all the infromation from the project.
  Contains the activity within the project from the users.
  Information of the payments made 
*/
contract TBContract is owned {
    

    struct TBProjects {
        
        address owner;
        string projectName;
        
        string milestoneData;
        string projectData;
        
        string[] paymentData;
        string[] activityData;
    }
    
    address owner;
    
    TBProjects[] public tbProjects;

    // mint the project with the project name, project data and the milestone details during the project creation.
    
    function initProject(string _project_name, string _project_data, string _milestone_data)
    public onlyOwner returns(uint256) {

        tbProjects[tbProjects.length].owner = msg.sender;
        tbProjects[tbProjects.length].projectName = _project_name;
        
        tbProjects[tbProjects.length].projectData = _project_data;
        tbProjects[tbProjects.length].milestoneData= _milestone_data;
        
        tbProjects.length++;
    }


    // Set payment details which will include milestone few details as well
    function setPaymentDetails(uint256 _id, string _payment_data)
    public onlyOwner returns(uint256) {
        
        tbProjects[_id].paymentData[tbProjects[_id].paymentData.length] = _payment_data;
        tbProjects[_id].paymentData.length++;
    }
    
    // Set activity details in the project
    function setActivityDetails(uint256 _id, string _activity_data)
    public onlyOwner returns(uint256) {

        tbProjects[_id].activityData[tbProjects[_id].activityData.length] = _activity_data;
        tbProjects[_id].activityData.length++;
    }

    // Getters for project by id for all detialed Information
    function getProjectById(uint256 _id) onlyOwner public returns(string, string, string[], string[]) {
        
        require(_id < tbProjects.length);
        
        return (
            tbProjects[_id].projectData,
            tbProjects[_id].milestoneData,
            tbProjects[_id].paymentData,
            tbProjects[_id].activityData);
    }
            
     // Getters for milestones Information
    function getMilestoneInformation(uint256 _id) onlyOwner public returns(string) {
    
        require(_id < tbProjects.length);
    
        return (
            tbProjects[_id].milestoneData);
    }
            
    // Getters for project Information
    function getProjectInformation(uint256 _id) onlyOwner public returns(string) {
       
        require(_id < tbProjects.length);
       
        return (
            tbProjects[_id].projectData);
    }
            
    // Getters for payment all Information
    function getAllPayment(uint256 _id) onlyOwner public returns(string[]) {
        
        require(_id < tbProjects.length);
        
        return (
            tbProjects[_id].paymentData);
    }
            
    // Getters for activity all Information
    function getAllActivity(uint256 _id) onlyOwner public returns(string[]) {
        
        require(_id < tbProjects.length);
        
        return (
            tbProjects[_id].activityData);
    }
            
    // Getters for payment single Information
    function getPaymentById(uint256 _id, uint256 _p_id) onlyOwner public returns(string) {
        
        require(_id < tbProjects.length);
        require(_p_id < tbProjects[_id].paymentData.length);
        
        return (
            tbProjects[_id].paymentData[_p_id]);
    }
            
     // Getters for activity single Information
    function getActivityById(uint256 _id, uint256 _a_id) onlyOwner public returns(string) {
        
        require(_id < tbProjects.length);
        require(_a_id < tbProjects[_id].activityData.length);
        
        return (
            tbProjects[_id].activityData[_a_id]);
    }
}