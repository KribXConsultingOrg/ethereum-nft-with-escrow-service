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
    function getIndex(uint _tokenId, address _address) public returns(uint){
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


    //Internal function to transfer ownership of the NFT on a successful sale
    function transferPupper(uint _tokenId, address newOwner) public {

        require(ownerOf(_tokenId)==msg.sender, "This wallet is not the owner of this NFT");
        safeTransferFrom(msg.sender, newOwner, _tokenId);
        uint index = getIndex(_tokenId, msg.sender);

        puppers[msg.sender][index]= puppers[msg.sender][puppers[msg.sender].length-1];
        puppers[msg.sender].pop();


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



    //Contract owner can set his commission % on transactions, denominator is 1000
    function setFee(uint _devFee) public onlyOwner {

        transactionFee = _devFee;

    }
    function setContractState(bool _state) public onlyOwner{
        pauseContract = _state;
    }
    function setNewOwner(address _address) public onlyOwner{
        _transferOwnership(_address);
    }
    //Contract Owner can withdraw his commission from transactions
    function withdrawDevCommission() public onlyOwner{
        address payable receiver = payable(owner());
        require(commission>0);

        if(receiver.send(commission)){
            commission =0;

        }
    }
    
    

       



}