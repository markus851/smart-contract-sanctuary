pragma solidity ^0.4.22;

contract assignmentTwo {
    uint public studentNumber;
    address public student;
    uint256 public gasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    
    function setGasUsed(uint256 _gasUsed) public {
        gasUsed = _gasUsed;
    }
}