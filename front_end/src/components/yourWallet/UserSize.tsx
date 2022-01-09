import { Token } from "../Main"
import { useEthers, useTokenBalance, useContractCall } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Content2Msg } from "../Content2Msg"

import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"

export interface UserSizeProps {
    token: Token
}

export const UserSize = ({ token }: UserSizeProps) => {
    // address
    // abi
    // chainId
    const { chainId, account } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)
    const { image, address, name } = token

    const [tokenBalance] =
        useContractCall(
            account &&
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "userSize", // Method to be called
                args: [account], // Method arguments - address to be checked for balance
            }
        ) ?? [];
    //console.log("user size:", tokenBalance)

    const formattedTokenBalance: number = tokenBalance ? parseFloat(formatUnits(tokenBalance, 18)) : 0


    return (<Content2Msg
        label={`当结算价>=3000，到期您能收到` + (tokenBalance / 1e18).toFixed(2)
            + 'USDx; 当结算价<3000，到期您能收到' + (tokenBalance / 1e18 / 3000).toFixed(4) + 'ETH'} />)
}
