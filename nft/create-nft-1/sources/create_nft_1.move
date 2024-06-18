module owner::create_nft_1 {
  use std::bcs;
  use std::error;
  use std::signer;
  use std::string::{Self, String};
  use std::vector;

  use aptos_token::token;
  use aptos_token::token::TokenDataId;

  // This struct stores an NFT collection's relevant information
  struct ModuleData has key {
    token_data_id: TokenDataId,
  }

  /// Action not authorized because the signer is not the admin of this module
  const ENOT_AUTHORIZED: u64 = 1;

  /// `init_module` is automatically called when publishing the module.
  /// In this function, we create an example NFT collection and an example token.
  fun init_module(source_account: &signer) {
    let collection_name = string::utf8(b"Collection name");
    let description = string::utf8(b"Description");
    let collection_uri = string::utf8(b"Collection uri");
    let token_name = string::utf8(b"Token name");
    let token_uri = string::utf8(b"Token uri");
    let maximum_supply = 0;
    let mutate_setting = vector<bool>[false, false, false];

    token::create_collection(source_account, collection_name, description, collection_uri, maximum_supply, mutate_setting);

    let token_data_id = token::create_tokendata(
      source_account,
      collection_name,
      token_name,
      string::utf8(b""),
      0,
      token_uri,
      signer::address_of(source_account),
      1,
      0,
      token::create_token_mutability_config(
        &vector<bool>[false, false, false, false, true]
      ),
      vector<String>[string::utf8(b"given_to")],
      vector<vector<u8>>[b""],
      vector<String>[string::utf8(b"address")],
    );

    move_to(source_account, ModuleData {
      token_data_id,
    });
  }

  /// Mint an NFT to the receiver. Note that here we ask two accounts to sign: the module owner and the receiver.
  /// This is not ideal in production, because we don't want to manually sign each transaction. It is also
  /// impractical/inefficient in general, because we either need to implement delayed execution on our own, or have
  /// two keys to sign at the same time.
  /// In part 2 of this tutorial, we will introduce the concept of "resource account" - it is
  /// an account controlled by smart contracts to automatically sign for transactions. Resource account is also known
  /// as PDA or smart contract account in general blockchain terms.
  public entry fun delayed_mint_event_ticket(module_owner: &signer, receiver: &signer) acquires ModuleData {
    let owner_address = signer::address_of(module_owner);

    assert!(owner_address == @owner, error::permission_denied(ENOT_AUTHORIZED));

    let module_data = borrow_global_mut<ModuleData>(@owner);
    let token_id = token::mint_token(module_owner, module_data.token_data_id, 1);
    token::direct_transfer(module_owner, receiver, token_id, 1);

    let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);
    token::mutate_token_properties(
      module_owner,
      signer::address_of(receiver),
      creator_address,
      collection,
      name,
      0,
      1,
      vector<String>[string::utf8(b"given_to")],
      vector<vector<u8>>[bcs::to_bytes(&signer::address_of(receiver))],
      vector<String>[string::utf8(b"address")],
    );
  }
}
