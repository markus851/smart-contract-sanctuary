pragma solidity ^0.4.25;

////設定管理者
contract owned {
    address public owner;

    constructor()public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

// erc20 interface
contract erc20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract byt_str {
    function stringToBytes32(string memory source) pure public returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function bytes32ToString(bytes32 x) pure public returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

// bitape contract
contract bitape is owned, byt_str{

  address token_address = 0x0 ; //bitape coin address
  uint pay = 5*10**18 ; //every update to pay

  struct process {
      address buyer;
      address seller;
      address sensor;
      data_base[] data;
  }

  struct data_base {
    uint8 _stage; //物流階段
    uint8 _report; //異常發報
    uint16 _temperature; //目前溫度
    uint16 _humidity; //目前濕度
    uint8 _vendor; //物流廠商
    uint32 _deliveryman; //送貨員編號
    uint32[2] _location; //位置
    bytes32 _remarks; //備註
    uint _time;  //時間
    
    //追蹤編號 物流階段 異常發報 目前溫度 濕度
    //物流廠商 送貨員編號 位置查詢 備註 時間
  }

  mapping (address => uint) info;
  //接收代幣支付用
 
  
  mapping (uint => process) all_data;
  //"服務編號" => 數組 => data結構體

  event write_data(address indexed from, uint _time, string _event);

//服務

  function start_service(address _seller) public{  
    uint _number = uint(keccak256(abi.encodePacked(msg.sender, now)));
    //data_base memory _start = data_base(0,0,null,null,null,null);
    all_data[_number].buyer = msg.sender ;
    all_data[_number].seller = _seller ;
    //all_data[_number].data.push(_start);
  }
  
  function start_service2(uint _number, address _sensor) public{
      all_data[_number].sensor = _sensor;
  }

  function update_event(
    uint _number, //追蹤編號
    uint8 _stage, //物流階段
    uint8 _report, //異常發報
    uint16 _temperature, //目前溫度
    uint16 _humidity, //目前濕度
    uint8 _vendor, //物流廠商
    uint32 _deliveryman, //送貨員編號
    uint32[2] _location, //位置
    string _remarks_str, //備註
    uint _time  //時間
  ) public{
    require(msg.sender == all_data[_number].sensor);
    bytes32 _remarks_byt = stringToBytes32(_remarks_str);
    
    data_base memory _data = data_base(
        _stage, //物流階段
        _report, //異常發報
        _temperature, //目前溫度
        _humidity, //目前濕度
        _vendor, //物流廠商
        _deliveryman, //送貨員編號
        _location, //位置
        _remarks_byt, //備註
        _time  //時間;
        );
    all_data[_number].data.push(_data);
  }
  
  function inquire_length(uint _number) public view returns(uint){
      require(msg.sender == all_data[_number].buyer
      || msg.sender == all_data[_number].seller);
    
    uint _length = all_data[_number].data.length;
    return _length;
    //查詢該追蹤編號擁有幾筆data
  }
  
  function inquire(uint _number, uint _sort) public view returns(
    uint8 _stage, //物流階段
    uint8 _report, //異常發報
    uint16 _temperature, //目前溫度
    uint16 _humidity, //目前濕度
    uint8 _vendor, //物流廠商
    uint32 _deliveryman, //送貨員編號
    uint32[2] _location, //位置
    string _remarks, //備註
    uint _time  //時間
        ){
      require(msg.sender == all_data[_number].buyer
      || msg.sender == all_data[_number].seller);
      
      bytes32  _remarks_byt = all_data[_number].data[_sort]._remarks;
      string memory  _remarks_str = bytes32ToString(_remarks_byt);
      
      _stage = all_data[_number].data[_sort]._stage;
      _report = all_data[_number].data[_sort]._report;
      _temperature = all_data[_number].data[_sort]._temperature;
      _humidity = all_data[_number].data[_sort]._humidity;
      _vendor = all_data[_number].data[_sort]._vendor;
      _deliveryman = all_data[_number].data[_sort]._deliveryman;
      _location = all_data[_number].data[_sort]._location;
      _remarks = _remarks_str;
      _time = all_data[_number].data[_sort]._time;
  }
  
//跨合約支付

  function pay_coin() payable public{
    require(erc20Interface(token_address).approve(msg.sender, pay));
  }

  function receiveApproval(address _sender, uint256 _value, address _tokenContract,
    bytes _extraData) public{
      require(_tokenContract == token_address);
      require(_value == pay);
      require(erc20Interface(token_address).transferFrom(_sender, address(this), _value));
      uint256 payloadSize;
      uint256 payload;
      assembly {
        payloadSize := mload(_extraData)
        payload := mload(add(_extraData, 0x20))
      }
      payload = payload >> 8*(32 - payloadSize);
      info[msg.sender] = payload;
    }

  }