pragma solidity ^0.4.0;
//扑克牌(梭哈)
contract Carding{
     struct User{
         address other;  //其他玩家的地址
         string[5] card; //自己的手牌
         uint spend;  //自己投了多少钱
         uint total;   //奖池总共金额
     }     
  
  mapping(address=>User) user;  //玩家地址映射玩家对象
      
    uint[4] color;
    uint[13] point;
    uint[52]cards;
  function poker()public returns (uint[52]){
    // color[0]=1; color[1]=2;color[2]=3;color[3]=4;
    
    // point[0]=2;point[1]=3;point[2]=4;point[3]=5;point[4]=6;point[5]=7;point[6]=8;
    // point[7]=9;point[8]=10;point[9]=11;point[10]=12;point[11]=13;point[12]=14;
    
    cards=[102,103,104,105,106,107,108,109,110,111,112,113,114,202,203,204,205,206,207,208,209,210,211,212,213,214,
          302,303,304,305,306,307,308,309,310,311,312,313,314,402,403,404,405,406,407,408,409,410,411,412,413,414];
  }
   
   
    uint public randNonce = 0;
    uint public random;
    
     function rand()public returns(uint){
         random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
         randNonce++;
        //  uint random2 = uint(keccak256(now, msg.sender, randNonce)) % 100;
        return random;
  }
  
  //随机打乱牌
  uint[52]  public newCard;
  uint n=0;uint result; bool[52] boo;
   function disrupt()public returns(uint[52]){
       for(uint8 i=0;i<200;i++){
        result=rand();
        if(!boo[result]){
         newCard[n]=cards[result];
         n++;
         boo[result]=true;
          if(n==52){
             break;
          }
        }else{
            continue;
        }
       } 
       
   }
   
}