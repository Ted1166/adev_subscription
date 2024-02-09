// Successfully deploying the Smart Contract in Starknet Devnet

// The contract generated class hash is 0x04d07e40e93398ed3c76981e72dd1fd22557a78ce36c0515f679e27f0bb5bc5f
// The contract class harsh declared is 0x04c29bca3d6ccbbf7d16e1611bc1774d7769aee3b66c4269b7e2bc53e3e182bf
// The Contract deployed on this address 0x01e020b6fde09f00c338c243b3b2469c6556786c4448951f18537b24ddba9bbd

// starkli declare class hash 0x04c29bca3d6ccbbf7d16e1611bc1774d7769aee3b66c4269b7e2bc53e3e182bf
// starkli contract address 0x053c42c0e04c754750f79b8f64fcacb2eceb012b303643ad6ba510b6d04fbafb
use adev_subscription::channel::Subscribe::{Packages, Msg, Subscription, ContractAddress,MediaFile,Channel};
use core::array::ArrayTrait;


#[starknet::interface]
trait subscribeTrait<TContractState> {
    fn get_asset_price(self: @TContractState, asset_id: felt252) -> u128;
    fn add_package(ref self:TContractState, sub_package : felt252, channels : felt252, price : u128);
    fn get_package(self:@TContractState, key:u128) -> Packages;
    fn subs_package(ref self:TContractState, package_id : u128, user : ContractAddress, key:u128, message_key:u128);
    fn get_message(self:@TContractState, key:u128) -> Msg;
    fn get_packages(self: @TContractState) -> Array<Packages>;
    fn create_channel(ref self:TContractState,channel_name:felt252);
    fn get_channel(self:@TContractState,key:u128) -> Channel;
    fn get_channels(self:@TContractState) -> Array<Channel>;
    fn get_media_file(self:@TContractState,key:u128) -> MediaFile;
    fn get_media_by_channel(self:@TContractState,channel_id:u128) -> Array<MediaFile>;
    fn create_media_file(ref self:TContractState, channel_id:u128, cid:felt252);
    
    }

#[starknet::contract]
mod Subscribe {

    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use core::debug::PrintTrait;
    use pragma_lib::abi::{
            IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
            ISummaryStatsABIDispatcherTrait};
    use pragma_lib::types::{DataType, AggregationMode, PragmaPricesResponse};
    use alexandria_math::pow;

    const ETH_USD: felt252 = 19514442401534788;  //ETH/USD to felt252, can be used as asset_id
    const BTC_USD: felt252 = 18669995996566340;  //BTC/USD

    #[storage]
    struct Storage {
        packages : LegacyMap::<u128, Packages>,
        packages_count: u128,
        channel_count:u128,
        media_count:u128,
        subscriptions: LegacyMap::<u128, Subscription>,
        messages: LegacyMap::<u128, Msg>,
        pragma_contract: ContractAddress,
        summary_stats: ContractAddress,
        channels:LegacyMap::<u128, Channel>,
        media_files:LegacyMap::<u128, MediaFile>
    }

    #[constructor]
    fn constructor(ref self: ContractState, pragma_address: ContractAddress, summary_stats_address : ContractAddress) 
    {
        self.pragma_contract.write(pragma_address);
        self.summary_stats.write(summary_stats_address);
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Msg {
        recipient : ContractAddress,
        msg : felt252
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Packages {
        sub_package : felt252,
        package_id: u128,
        channels : felt252,
        price : u128
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Subscription {
        package_id : u128,
        user : ContractAddress
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct MediaFile {
        media_id : u128,
        cid : felt252,
        channel_id: u128
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Channel {
        channel_id : u128,
        channel_name : felt252,
        channel_owner: ContractAddress
    }



    #[abi(embed_v0)]
    impl subscribeImpl of super::subscribeTrait<ContractState> {

        fn get_asset_price(self: @ContractState, asset_id: felt252) -> u128 {
            // Retrieve the oracle dispatcher
            let oracle_dispatcher = IPragmaABIDispatcher {
                contract_address: self.pragma_contract.read()
            };

            // Call the Oracle contract, for a spot entry
            let output: PragmaPricesResponse = oracle_dispatcher
                .get_data_median(DataType::SpotEntry(asset_id));

            return output.price;
        }

        fn add_package(ref self:ContractState, sub_package : felt252, channels : felt252, price : u128) {
            let key_ = self.packages_count.read() + 1;
             let new_package = Packages{sub_package:sub_package, channels:channels, price:price, package_id:key_};
            self.packages.write(key_, new_package);
            self.packages_count.write(key_);
        }



        fn get_package(self:@ContractState,key:u128) -> Packages{
            self.packages.read(key)
        }

        fn subs_package(ref self:ContractState, package_id : u128, user : ContractAddress, key:u128, message_key:u128) {
            let user_subscribe = Subscription{package_id:package_id, user:user};
            let package = self.packages.read(package_id);
            if package.package_id == package_id {
                self.subscriptions.write(key, user_subscribe);
                self.messages.write(message_key, Msg{recipient:user, msg:'Subscription successful'});
            }
        }

        fn get_message(self:@ContractState, key:u128) -> Msg {
            self.messages.read(key)
        }

        fn get_packages(self: @ContractState) -> Array<Packages> {
            let mut packages = ArrayTrait::<Packages>::new();
            let total_packages = self.packages_count.read();
            let mut count = 1;

            if total_packages > 0{
                loop {
                    let package = self.packages.read(count);
                    packages.append(package);
                    count +=1;
                    if(count > total_packages){
                        break;
                    }
                }
            }
            packages
        }

        fn create_channel(ref self:ContractState,channel_name:felt252){

            let channel_id = self.channel_count.read() + 1;

            self.channel_count.write(channel_id);

            let channel_owner = get_caller_address();

            self.channels.write(channel_id,Channel{channel_id,channel_name,channel_owner});
        }

        fn get_channel(self:@ContractState,key:u128) -> Channel{
            self.channels.read(key)
        }

        fn get_channels(self:@ContractState) -> Array<Channel>{

            let mut channels = ArrayTrait::<Channel>::new();
            let total_channels = self.channel_count.read();
            let mut count = 1;

            if total_channels > 0{
                loop {
                    let channel = self.channels.read(count);
                    channels.append(channel);
                    count +=1;
                    if(count > total_channels){
                        break;
                    }
                }
            }
            channels
        }
        fn get_media_file(self:@ContractState,key:u128) -> MediaFile{
            self.media_files.read(key)
        }

        fn get_media_by_channel(self:@ContractState,channel_id:u128) -> Array<MediaFile>{

            let mut media_files = ArrayTrait::<MediaFile>::new();
            let total_channel_media_files = self.media_count.read();
            let mut count = 1;

            if total_channel_media_files > 0{
                loop {
                    let media_file = self.media_files.read(count);

                    if (media_file.channel_id == channel_id){
                        media_files.append(media_file);
                    }

                    count +=1;
                    if(count > total_channel_media_files){
                        break;
                    }
                }
            }

            media_files

        }

        fn create_media_file(ref self:ContractState, channel_id:u128,cid:felt252){

            let media_id = self.media_count.read() +1;

            self.media_count.write(media_id);

            self.media_files.write(media_id, MediaFile {media_id,cid,channel_id});

        }
    }
}

#[cfg(test)]
mod tests {
    use adev_subscription::channel::subscribeTraitDispatcherTrait;
    // use super::subscribe;
    use super::subscribeTraitDispatcher;
    use core::array::ArrayTrait;
    use starknet::{ContractAddress,contract_address_const};
    use core::debug::PrintTrait;
    use snforge_std::{declare, ContractClassTrait};


    fn deploy() -> subscribeTraitDispatcher {
        // let mut calldata: Array<felt252> = ArrayTrait::new();
        // let (address0, _) = deploy_syscall(subscribe::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false).unwrap();
        // subscribeTraitDispatcher { contract_address: address0}
        let contract = declare('Subscribe');
        let contract_address = contract.deploy(@ArrayTrait::new()).unwrap();
        // Create a Dispatcher object for interaction with the deployed contract
        subscribeTraitDispatcher { contract_address }
    }

    #[test]
    #[available_gas(20000000)]
    fn test_add_package(){
        let mut contract = deploy();
        let sub_package = 'sub_package';
        let channels = '1,2,3';
        let price = 1000;

        contract.add_package(sub_package,channels,price);

        let package_sent = contract.get_package(1);

        assert(package_sent.channels == '1,2,3', 'package channels');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_subs_package() {
        let mut contract = deploy();
        let _package_id = 1;
        let user: ContractAddress =  contract_address_const::<0x00000>();

        let sub_package = 'sub_package';
        let channels = '1,2,3';
        let price = 1000;

        contract.add_package(sub_package,channels,price);

        contract.subs_package(1, user,1,1);

        let message = contract.get_message(1);
        assert(message.msg == 'Subscription successful', 'Message');
    }

}


// Account #2:
// Address: 0x45387bf30f69b713c9777f9331f209216fec0cc262c0c3a05a22d34d9024706
// Public key: 0x489549486368950820e896ce81972ff1c52ba0349688c416c64784927a46258
// Private key: 0x6e0dedd76b71dee7398355169a7d3def