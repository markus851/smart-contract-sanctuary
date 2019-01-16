pragma solidity ^0.4.22;

contract ERC20Interface {
  string public name;
  string public symbol;
  uint8 public  decimals;
  uint public totalSupply;

  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
}

contract GodOfWealth is ERC20Interface {

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) internal allowed;
    
     event Burn(address indexed from, uint256 value);
    
    constructor() public {
        totalSupply = 10000000000000000;
        name = "God of Wealth";
        symbol = "GOW";
        decimals = 8;
        balanceOf[msg.sender] = totalSupply;
    }

  function balanceOf(address _owner) view returns (uint256 balance) {
      return balanceOf[_owner];
  }

  function transfer(address _to, uint _value) public returns (bool success) {
      require(_value <= balanceOf[msg.sender]);
      require(balanceOf[_to] + _value >= balanceOf[_to]);

      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(_value <= balanceOf[_from]);
      require(_value <= allowed[_from][msg.sender]);
      require(balanceOf[_to] + _value >= balanceOf[_to]);

      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;

      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    }

  function approve(address _spender, uint256 _value) returns (bool success) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) view returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }
  
   function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

}