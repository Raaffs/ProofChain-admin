    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Verification{
    address owner;
    constructor(){
        owner=msg.sender;
    }
    enum DocStatus{
        accepted,
        rejected,
        pending
    }
    struct User{
        string publicKey;   
    }
    struct Institution{
        address publicAddr;
        string  publicKey;
        string  name;
        bool    approved;
    }
    struct Document{
        address     requester;
        address     verifiedBy;
        string      institution; 
        string      name;
        string      encrpytedIPFSHash;
        DocStatus   status;
        uint        index;
    }
    //each institution can only have one verifier, at least for now. 
    mapping(string=>Institution) public institutions;
    mapping(address=>User) private users;
    //sha3 to map documents and verify the document's integrity 
    mapping(string=>uint) private documentList;
    mapping(address=>bool) userList;
    
    address[]   requesters;
    address[]   verifiedBy; 
    string[]    names;
    string[]    documentHash;
    string[]    institution;
    string[]    descriptions;
    string[]    encrpytedIPFSHashes; 
    DocStatus[] status;
    //all the above arrays depends on  'docIndexCounter' variable
    //potential improvement: use mapping(user=>[]docs) and mapping(institute=>[]docs)
    //that way there won't be a need to rely and keep track of all these arrays separately
    
    //Though I am not sure if this is cost efficient, since there will be a need to iterate 
    //over  both, user and institute's arrays and update them separately
    uint docIndexCounter=0;
    function registerAsUser(string calldata _publicKey) public{
        users[msg.sender]=User({
            publicKey:  _publicKey
        });
        userList[msg.sender]=true;
    }
    
    function registerInstitution(string memory _publicKey, string memory _name) public{
        require(institutions[_name].publicAddr == address(0), "Institution already registered");
        institutions[_name]=Institution({
            publicAddr: msg.sender,
            publicKey:  _publicKey,
            name:       _name,
            approved:   false
        });
    }

    function getInstituePublicKey(string memory _name) public view returns(string memory pubKey){
        return institutions[_name].publicKey;
    }
    function getUserPublicKey(address userAddr)public view returns (string memory){
        return users[userAddr].publicKey;        
    }
    function approveVerifier(string memory _name)public{
        require(msg.sender==owner,"Only admin can perfom this action");
        institutions[_name].approved=true;
    }
    function addDocument(string memory shaHash,string memory _EncryptedIPFSHash, string memory _institute,string memory _name ) public{
        bool isUser=userList[msg.sender];
        require(isUser==true,"register first to verify");
        documentList[shaHash]=docIndexCounter;
        requesters.push(msg.sender);
        verifiedBy.push(address(0));
        institution.push(_institute);
        names.push(_name);
        status.push(DocStatus.pending);
        encrpytedIPFSHashes.push(_EncryptedIPFSHash);
        documentHash.push(shaHash);
        docIndexCounter++;
    }
    //returns all the documents
    function getDocuments()public view returns(address[] memory requester ,address[] memory verifer ,string[] memory institute,string[] memory ipfs,string[] memory name,string[] memory hash,DocStatus[] memory stats){
        return (requesters,verifiedBy,institution,encrpytedIPFSHashes,names,documentHash,status);
    }
    
    function verifyDocument(string memory shaHash,string memory _institute,  DocStatus _status)public payable {
        require(institutions[_institute].approved==true && institutions[_institute].publicAddr==msg.sender);
        uint index=documentList[shaHash];
        status[index]=_status;
        verifiedBy[index]=msg.sender;
    }
    function getDocIndexCounter()public view returns(uint) {
        return docIndexCounter;
    }   
    function getDocumentIndex(string  memory shaHash)public view returns(uint){
        return documentList[shaHash];
    }
    function isApprovedInstitute(string memory name)public view returns (bool){
        return institutions[name].approved==true;
    }
}        
//test