pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Pupper is ERC721, Ownable {

    
    
    uint pupperId=0;    
    bool pauseContract;
    uint public transactionFee;
    uint public commission; 
    
    //Access control for contract owner to pause functionality after a new upgraded contract is deployed
    modifier contractPaused(){
        require(pauseContract == true);
        _;
    }

    modifier contractNotPaused(){
        require(pauseContract == false);
        _;
    }
    //Initializing name and symbol for the NFT
    constructor() ERC721("Pupper", "PUP") {}   

    //Creating a struct to save different attributes of the NFT
    struct pupper{

        
        uint _pupperId;
        string _pupperName;
        string _breed;
        string _sex;
        string _genome;
        string _genomeTestResultLink;
        string _imageBase64;
        uint _salePrice;
        uint _breedingPrice;
        bool _enableBreeding;
        bool _enableSale;
        
    }
     

    mapping(address=>pupper[]) public puppers;

    mapping(uint => pupper) public allpuppers;
    mapping (string=>bool) public genomes;

    //Function to get the index of the NFT in puppers mapping to wallet address
    function getIndex(uint _tokenId, address _address) private returns(uint){
        uint index;

        for(uint i=0; i<puppers[_address].length-1; i++){
            
            if(puppers[_address][i]._pupperId==_tokenId){

                index =i;
            }

        }
        return index;
    }
    
    //To mint your dogs NFT
    function createPupper(string memory pupperName, string memory _breed, 
    string memory sex, string memory genome, string memory 
    genomeLink, string memory base64) public contractNotPaused{

        require(genomes[genome]==false, "This Property Already Exists As NFT");

        pupperId+=1;

        _safeMint(msg.sender, pupperId);

        puppers[msg.sender].push(pupper(pupperId, pupperName, _breed, sex, genome,genomeLink,base64,0,0,false,false));
        allpuppers[pupperId]= pupper(pupperId, pupperName, _breed, sex, genome,genomeLink,base64,0,0,false,false);
        genomes[genome]= true;
        
    }

    function transferPupper(uint _tokenId, address newOwner) private {

        require(ownerOf(_tokenId)==msg.sender, "This wallet is not the owner of this NFT");
        safeTransferFrom(msg.sender, newOwner, _tokenId);
        uint index = getIndex(_tokenId, msg.sender);

        puppers[msg.sender][index]= puppers[msg.sender][puppers[msg.sender].length-1];
        puppers[msg.sender].pop();


    }

    function enableSale(uint _tokenId, uint _salePrice) public  contractNotPaused{
        require(ownerOf(_tokenId)==msg.sender,"This wallet doesn't own this wallet");
        require(allpuppers[_tokenId]._enableBreeding==false, "You can't sell while breeding is enabled");

        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableSale =true;
        puppers[msg.sender][index]._salePrice =_salePrice;

        allpuppers[_tokenId]._enableSale=true;
        allpuppers[_tokenId]._salePrice =_salePrice;


    }
    function disableSale(uint _tokenId) public {

        require(ownerOf(_tokenId)==msg.sender,"Wallet is not the owner of this NFT");
        require(escrows[_tokenId]._amount ==0, "Deal is currently in Escrow");
        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableSale =false;
        puppers[msg.sender][index]._salePrice =0;

        allpuppers[_tokenId]._enableSale=false;
        allpuppers[_tokenId]._salePrice =0;

    }

    

    function enableBreeding(uint _tokenId, uint _breedingPrice) public contractNotPaused{
        require(ownerOf(_tokenId)==msg.sender,"This wallet doesn't own this wallet");
        require(allpuppers[_tokenId]._enableSale==false, "You can't breed while sale is enabled");

        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableBreeding =true;
        puppers[msg.sender][index]._breedingPrice =_breedingPrice;

        allpuppers[_tokenId]._enableBreeding=true;
        allpuppers[_tokenId]._breedingPrice =_breedingPrice;


    }

    function disableBreeding(uint _tokenId) public{
        require(ownerOf(_tokenId)==msg.sender,"Wallet is not the owner of this NFT");
        require(escrows[_tokenId]._amount ==0, "Deal is currently in Escrow");

        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableBreeding =false;
        puppers[msg.sender][index]._breedingPrice =0;

        allpuppers[_tokenId]._enableBreeding=false;
        allpuppers[_tokenId]._breedingPrice =0;

    }

    struct escrow{
            uint _amount;
            address _sender;
            address _receiver;
            string _type;
            bool _senderApproval;
            bool _receiverApproval;
            bool _processed;
        }
    mapping(uint=>escrow) public escrows;

    function buy(uint _tokenId) public payable contractNotPaused{
        require(allpuppers[_tokenId]._enableSale==true);
        require(msg.value>=allpuppers[_tokenId]._salePrice);

        allpuppers[_tokenId]._enableSale==false;
        escrows[_tokenId]=escrow(msg.value,msg.sender,ownerOf(_tokenId), "SALE", false, false, false);


    }

    function breed(uint _tokenId) public payable contractNotPaused{
        require(allpuppers[_tokenId]._enableBreeding==true);
        require(msg.value>=allpuppers[_tokenId]._breedingPrice);

        allpuppers[_tokenId]._enableBreeding==false;
        escrows[_tokenId]=escrow(msg.value,msg.sender,ownerOf(_tokenId), "BREEDING", false, false, false);


    }

    function approveTransaction(uint _tokenId) public {
        require(msg.sender == escrows[_tokenId]._sender || msg.sender == escrows[_tokenId]._receiver);
        require(escrows[_tokenId]._processed==false);
        if (msg.sender ==escrows[_tokenId]._sender){
            escrows[_tokenId]._senderApproval = true;
        }else
        {
            escrows[_tokenId]._receiverApproval = true;
        }


    }

    function processEscrow(uint _tokenId) public{
        require(msg.sender==ownerOf(_tokenId));
        require(escrows[_tokenId]._senderApproval == true && escrows[_tokenId]._receiverApproval == true && escrows[_tokenId]._processed == false);
        //Converting the address to payable
        address payable receiver = payable(escrows[_tokenId]._receiver);
        uint fee = escrows[_tokenId]._amount*(transactionFee/1000);
        uint amount = escrows[_tokenId]._amount-fee;

        if(receiver.send(amount)){
            if(keccak256(bytes(escrows[_tokenId]._type))==keccak256(bytes("SALE"))){
                transferPupper( _tokenId, escrows[_tokenId]._sender);
                escrows[_tokenId]._amount =0;
                escrows[_tokenId]._processed=true;
                commission+=fee;

            }else{
                escrows[_tokenId]._amount =0;
                escrows[_tokenId]._processed=true;
                commission+=fee;
            }
            

        }


    }
    function refundEscrow(uint _tokenId) public {

        require(escrows[_tokenId]._senderApproval == false && escrows[_tokenId]._receiverApproval == false && escrows[_tokenId]._processed == false );
        address payable receiver = payable(escrows[_tokenId]._sender);
        if(receiver.send(escrows[_tokenId]._amount)){
            escrows[_tokenId]._amount =0;
            escrows[_tokenId]._processed=true;

        }
    }
    function setFee(uint _devFee) public onlyOwner {

        transactionFee = _devFee;

    }
    //Owner can withdraw his commission 
    function withdrawDevCommission() public onlyOwner{
        address payable receiver = payable(owner());
        require(commission>0);

        if(receiver.send(commission)){
            commission =0;

        }
    }
    
    

       



}