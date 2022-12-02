import axios from "axios";

const RELAY_URL = "https://relay.gelato.digital";

export const relayV0Send = async (
  chainId: number,
  dest: string,
  data: string,
  relayerFee: string,
  gasLimit: number
): Promise<void> => {
  const params = {
    dest,
    data,
    token: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    relayerFee,
    gasLimit,
  };
  try {
    const response = await axios.post(`${RELAY_URL}/relays/${chainId}`, params);
    console.log(response.data);
  } catch (err: unknown) {
    console.error(`relayV0Send error: ${(err as Error).message}`);
  }
};
