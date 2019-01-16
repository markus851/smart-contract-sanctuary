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


//轉換string與byte32
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
contract new_bitape is owned, byt_str{

  bool Stop = false;
  
  uint number_index = 0 ;

  struct process {
      address buyer;
      address seller;
      address sensor;
      data_base[] data;
      bool start;
  }

  struct data_base {
    uint8 _stage; //物流階段
    uint8 _report; //異常發報
    uint16 _temperature; //目前溫度
    uint8 _humidity; //目前濕度
    uint8 _vendor; //物流廠商
    uint32 _deliveryman; //送貨員編號
    uint32[2] _location; //位置
    bytes32 _remarks; //備註
    uint32 _time;  //時間

    //追蹤編號 物流階段 異常發報 目前溫度 濕度
    //物流廠商 送貨員編號 位置查詢 備註 時間
  }

  mapping (address => uint) info;
  //接收代幣支付用


  mapping (uint => process) all_data;
  //"服務編號" => 數組 => data結構體

  event Update(address indexed sensor, uint indexed _number);
  event Start_service(address indexed starter, address sensor, uint number);
  event Stop_service(address indexed ender, address sensor, uint number);

//管理權限

  function start_all() public onlyOwner{
      Stop = false;
  }

  function stop_all() public onlyOwner{
      Stop = true;
  }

//啟用結束服務function
  
  function start_seller(address _buyer,address _sensor, uint32 _time) public{
      
    require(Stop == false);
    uint _number = number_index;
    all_data[_number].start = true;

    all_data[_number].buyer = _buyer ;
    all_data[_number].seller = msg.sender ;
    all_data[_number].sensor = _sensor ;

    data_base memory _data = data_base(
        0, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        [uint32(0),uint32(0)], //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);

    number_index += 1;
    
    emit Start_service(msg.sender, all_data[_number].sensor, _number);
  }
  
    function start_buyer(address _seller,address _sensor, uint32 _time) public{
    require(Stop == false);
    uint _number = number_index;
    all_data[_number].start = true;

    all_data[_number].buyer = msg.sender ;
    all_data[_number].seller = _seller ;
    all_data[_number].sensor = _sensor ;

    data_base memory _data = data_base(
        1, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        [uint32(0),uint32(0)], //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);

    number_index += 1;
    
    emit Start_service(msg.sender, all_data[_number].sensor, _number);
  }
  
  function stop_service(uint _number, uint32 _time) public{
      require(all_data[_number].start == true);
      require(msg.sender == all_data[_number].buyer
      || msg.sender == all_data[_number].seller);
      
        data_base memory _data = data_base(
        255, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        [uint32(0),uint32(0)], //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);
        all_data[_number].start = false;

        emit Stop_service(msg.sender, all_data[_number].sensor, _number);
  }

//上傳資料function
  function update_event(
    uint _number, //追蹤編號
    uint8 _stage, //物流階段
    uint8 _report, //異常發報
    uint16 _temperature, //目前溫度
    uint8 _humidity, //目前濕度
    uint8 _vendor, //物流廠商
    uint32 _deliveryman, //送貨員編號
    uint32[2] _location, //位置
    string _remarks_str, //備註
    uint32 _time  //時間
  ) public{
    require(msg.sender == all_data[_number].sensor);
    require(all_data[_number].start == true);

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
    
    emit Update(msg.sender, _number);
  }

//查詢用function

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
    uint8 _humidity, //目前濕度
    uint8 _vendor, //物流廠商
    uint32 _deliveryman, //送貨員編號
    uint32[2] _location, //位置
    string _remarks, //備註
    uint32 _time  //時間
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


  }