import { Account, Contract, Provider } from "starknet"
import contractJson from '../abi/adev_subscription_Subscribe.contract_class.json'

// export const CONTRACT_ADDRESS = "0x01ed24df20fe397ad8154462d1ab959b1c4760e2368a528e3d11e80f49a25ef7"
export const CONTRACT_ABI = contractJson.abi

// export const CONTRACT_ADDRESS = "0x01e020b6fde09f00c338c243b3b2469c6556786c4448951f18537b24ddba9bbd"
// export const ACCOUNT_ADDRESS = "0x45387bf30f69b713c9777f9331f209216fec0cc262c0c3a05a22d34d9024706"
// export const PRIVATE_KEY = "0x6e0dedd76b71dee7398355169a7d3def"
export const CONTRACT_ADDRESS = "0x070d07b3d0cc56e97077004e4bfdddc46d11f95411fa124a114484c011ab765f"
export const ACCOUNT_ADDRESS = "0x04B93FC07b2b6Da3520033D8f2BbeF9c42f9873837a4B3DE7a863EDC9e04B058"
export const PRIVATE_KEY = "0x05812f784f4d484ebc280f21931296e83954925b379ecc3ec1c1501728f8b31e"

const provider = new Provider({ rpc: { nodeUrl: "http://0.0.0.0:5050/rpc" } })
const account = new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY)
const contract = new Contract(abi, CONTRACT_ADDRESS, account)
contract.connect(account)

export { contract, account, provider }