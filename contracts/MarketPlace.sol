pragma solidity >=0.8.0;

import "./Pupper.sol";


contract MarketPlace is Pupper{

    //user can put their NFT for sale using this
    function enableSale(uint _tokenId, uint _salePrice) public  contractNotPaused{
        require(ownerOf(_tokenId)==msg.sender,"This wallet doesn't own this wallet");
        require(allpuppers[_tokenId]._enableBreeding==false, "You can't sell while breeding is enabled");

        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableSale =true;
        puppers[msg.sender][index]._salePrice =_salePrice;

        allpuppers[_tokenId]._enableSale=true;
        allpuppers[_tokenId]._salePrice =_salePrice;


    }

    //To disable sale of NFT if no one has put money in escrow for the purchase.
    function disableSale(uint _tokenId) public {

        require(ownerOf(_tokenId)==msg.sender,"Wallet is not the owner of this NFT");
        require(escrows[_tokenId]._amount ==0, "Deal is currently in Escrow");
        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableSale =false;
        puppers[msg.sender][index]._salePrice =0;

        allpuppers[_tokenId]._enableSale=false;
        allpuppers[_tokenId]._salePrice =0;

    }
    function buy(uint _tokenId) public payable contractNotPaused{
        require(allpuppers[_tokenId]._enableSale==true);
        require(msg.value>=allpuppers[_tokenId]._salePrice);

        allpuppers[_tokenId]._enableSale==false;
        escrows[_tokenId]=escrow(msg.value,msg.sender,ownerOf(_tokenId), "SALE", false, false, false);


    }


    
    //To open up your Dog for breeding
    function enableBreeding(uint _tokenId, uint _breedingPrice) public contractNotPaused{
        require(ownerOf(_tokenId)==msg.sender,"This wallet doesn't own this wallet");
        require(allpuppers[_tokenId]._enableSale==false, "You can't breed while sale is enabled");

        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableBreeding =true;
        puppers[msg.sender][index]._breedingPrice =_breedingPrice;

        allpuppers[_tokenId]._enableBreeding=true;
        allpuppers[_tokenId]._breedingPrice =_breedingPrice;


    }

    //To disable breeding if no one has put money in escrow for the service.
    function disableBreeding(uint _tokenId) public{
        require(ownerOf(_tokenId)==msg.sender,"Wallet is not the owner of this NFT");
        require(escrows[_tokenId]._amount ==0, "Deal is currently in Escrow");

        uint index = getIndex(_tokenId, msg.sender);
        puppers[msg.sender][index]._enableBreeding =false;
        puppers[msg.sender][index]._breedingPrice =0;

        allpuppers[_tokenId]._enableBreeding=false;
        allpuppers[_tokenId]._breedingPrice =0;

    }
    //Struct to define attributes of an escrow
    

    //Purchase any NFT up for sale, payment will be held in an escrow till both parties approve the transaction
    

    //Book a breeding session, payment will be held in an escrow till both parties approve the transaction
    function breed(uint _tokenId) public payable contractNotPaused{
        require(allpuppers[_tokenId]._enableBreeding==true);
        require(msg.value>=allpuppers[_tokenId]._breedingPrice);

        allpuppers[_tokenId]._enableBreeding==false;
        escrows[_tokenId]=escrow(msg.value,msg.sender,ownerOf(_tokenId), "BREEDING", false, false, false);


    }

    //Both parties approve sale/breeding transactions for payment to be released to the owner
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

    //After both parties approve the transaction owner can withdraw his payment from the escrow
    function processEscrow(uint _tokenId) public{
        require(msg.sender==ownerOf(_tokenId));
        require(escrows[_tokenId]._senderApproval == true);
        require(escrows[_tokenId]._receiverApproval == true);
        require(escrows[_tokenId]._processed == false);
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

    //Incase anyone wants to cancel the transaction incase both parties have no objection
    function refundEscrow(uint _tokenId) public {

        require(escrows[_tokenId]._senderApproval == false && escrows[_tokenId]._receiverApproval == false && escrows[_tokenId]._processed == false );
        address payable receiver = payable(escrows[_tokenId]._sender);
        if(receiver.send(escrows[_tokenId]._amount)){
            escrows[_tokenId]._amount =0;
            escrows[_tokenId]._processed=true;

        }
    }
}