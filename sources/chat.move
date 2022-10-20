  module deployer::chat {
	use std::string;
	use std::timestamp;
	use std::error;
	use aptos_std::table;
	use std::vector;
	use std::signer;

	const EMESSAGE_STORE_NOT_EXISTS: u64 = 1;
	const EPRIVATE_REQUEST_NOT_EXISTS: u64 = 2;
	const EPRIVATE_STORE_NOT_EXISTS: u64 = 3;
	const EPRIVATE_REQUEST_USER_ALREADY_EXISTS : u64 = 4;
	const EPRIVATE_REQUEST_USER_NOT_EXISTS : u64 = 5;

	struct MessageStore has key, store{
		messages: table::Table<address, vector<Message>>,
	}

	struct All_Contact has key, store {
		contacts : vector<address>,
	}

	struct Proactive_Contact has key, store {
		contacts : vector<address>,
	}

	struct MessageInfo has drop, store, copy {
		timestamp: u64,
		sender: address,
	}

	struct Message has store, drop, copy {
		info : MessageInfo,
		content: string::String,
	}

	public entry fun init_store(account: &signer) {
		let store = MessageStore{messages: table::new<address, vector<Message>>()};
		move_to(account, store);
		
		move_to(account, All_Contact{contacts: vector::empty<address>()});
		move_to(account, Proactive_Contact{contacts: vector::empty<address>()});
	}

	public entry fun send(sender : &signer, to: address, _message: vector<u8>) acquires MessageStore, All_Contact, Proactive_Contact{
		assert!(
            exists<MessageStore>(signer::address_of(sender)),
            error::not_found(EMESSAGE_STORE_NOT_EXISTS),
        );

		assert!(
            exists<MessageStore>(to),
            error::not_found(EMESSAGE_STORE_NOT_EXISTS),
        );

		let content = string::utf8(_message);
		let info = MessageInfo{timestamp:timestamp::now_microseconds(), sender: signer::address_of(sender)};
		let message = Message {info, content};

		let message_store_sender = &mut borrow_global_mut<MessageStore>(signer::address_of(sender)).messages;

		let sender_messages = table::borrow_mut_with_default(message_store_sender,to,vector::empty<Message>());
		vector::push_back<Message>(sender_messages,message);

		let message_store_receiver = &mut borrow_global_mut<MessageStore>(to).messages;

		let receiver_messages = table::borrow_mut_with_default(message_store_receiver,signer::address_of(sender),vector::empty<Message>());
		vector::push_back<Message>(receiver_messages,message);

		let sender_all_contact = &mut borrow_global_mut<All_Contact>(signer::address_of(sender)).contacts;
		if(!vector::contains(sender_all_contact,&to)){
			vector::push_back<address>(sender_all_contact,to);
		};

		let to_all_contact = &mut borrow_global_mut<Proactive_Contact>(to).contacts;
		if(!vector::contains(to_all_contact,&signer::address_of(sender))){
			vector::push_back<address>(to_all_contact,signer::address_of(sender));
		};

		let sender_proactive_contact = &mut borrow_global_mut<Proactive_Contact>(signer::address_of(sender)).contacts;
		if(!vector::contains(sender_proactive_contact,&to)){
			vector::push_back<address>(sender_proactive_contact,to);
		};
	}
  }