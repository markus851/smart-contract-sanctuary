pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}

/**
 * @title contract owner
 */
contract Ownable {
    
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title credit value owner
 */
contract Creditable {
    
    address public creditor;
    
    mapping(address => uint) public freezeCredits;

    modifier onlyCreditor() {
        require(msg.sender == creditor);
        _;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, Creditable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];

        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused);
        _;
    }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract BlackList is Ownable, BasicToken {

    /**
     * Getters to allow the same blacklist to be used also by other contracts 
     */
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

}


/**
 * Credit Value Token
 */
contract CreditToken is Pausable, StandardToken, BlackList {
    
    string public name;
    string public symbol;
    uint public decimals;

    // token version
    uint public version = 1;
    // token relative address 
    address public relativeAddress;
    // total credit score
    uint public totalCreditScore;
    // credit scores that are allowed to be used
    uint public allowedCreditScore;
    // frozen credit score in business scenario
    uint public freezeCreditScore;
    
    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _initialSupply Initial supply of the contract
    // @param _decimals Token decimals
    // @param _creditor credit value owner
    // @param _creditScore Initial evaluation credit token Score
    // @param _relativeAddress Token relative address
    constructor(string _name, string _symbol, uint _initialSupply, uint _decimals, address _creditor, uint _creditScore, address _relativeAddress) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        
        creditor = _creditor;
        totalCreditScore = _creditScore;
        allowedCreditScore = _creditScore;
        relativeAddress = _relativeAddress;
    }

    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address who) public view returns (uint) {
        return super.balanceOf(who);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        return super.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return super.allowance(_owner, _spender);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function addCreditScore(uint _score, string _message) public onlyOwner {
        require(totalCreditScore.add(_score) < MAX_UINT);
        totalCreditScore = totalCreditScore.add(_score);
        allowedCreditScore = allowedCreditScore.add(_score);
        emit AddCreditScore(msg.sender, creditor, _score, _message, totalCreditScore, allowedCreditScore, freezeCreditScore);
    }
    
    function subCreditScore(uint _score, string _message) public onlyOwner {
        require(allowedCreditScore.sub(_score) >= 0);
        totalCreditScore = totalCreditScore.sub(_score);
        allowedCreditScore = allowedCreditScore.sub(_score);
        emit AddCreditScore(msg.sender, creditor, _score, _message, totalCreditScore, allowedCreditScore, freezeCreditScore);
    }
    
    function freezeCreditScore(address _receiver, uint _score, string _message) public onlyCreditor whenNotPaused {
        require(!isBlackListed[msg.sender]);
        require(allowedCreditScore.sub(_score) >= 0);
        require(freezeCredits[_receiver].add(_score) < MAX_UINT);
        
        allowedCreditScore = allowedCreditScore.sub(_score);
        freezeCreditScore = freezeCreditScore.add(_score);
        freezeCredits[_receiver] = freezeCredits[_receiver].add(_score);
        emit FreezeCreditScore(msg.sender, _receiver, _score, _message, totalCreditScore, allowedCreditScore, freezeCreditScore);
    }
    
    function unfreezeCreditScore(uint _score, string _message) public onlyPayloadSize(2 * 32){
        require(totalCreditScore.add(_score) < MAX_UINT);
        require(freezeCredits[msg.sender].sub(_score) >= 0);
        
        allowedCreditScore = allowedCreditScore.add(_score);
        freezeCreditScore = freezeCreditScore.sub(_score);
        freezeCredits[msg.sender] = freezeCredits[msg.sender].sub(_score);
        emit FreezeCreditScore(msg.sender, creditor, _score, _message, totalCreditScore, allowedCreditScore, freezeCreditScore);
    }

    function setRelativeAddress(address newRelativeAddress) public onlyOwner {
        relativeAddress = newRelativeAddress;
        emit SetRelativeAddress(relativeAddress);
    }

    // event functions
    event AddCreditScore(address sender, address receiver ,uint score, string message, uint totalCreditScore, uint allowedCreditScore, uint uintfreezeCreditScore);
    event SubCreditScore(address sender, address receiver ,uint score, string message, uint totalCreditScore, uint allowedCreditScore, uint uintfreezeCreditScore);
    event FreezeCreditScore(address sender, address receiver, uint score, string message, uint totalCreditScore, uint allowedCreditScore, uint uintfreezeCreditScore);
    event UnfreezeCreditScore(uint score, string message, uint totalCreditScore, uint allowedCreditScore, uint uintfreezeCreditScore);
    event SetRelativeAddress(address relativeAddress);
}