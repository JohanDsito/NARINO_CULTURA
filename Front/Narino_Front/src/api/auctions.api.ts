import axiosInstance from './axiosInstance'
import type { Auction, Bid, PaginatedResponse } from '@/types/auth'

export interface GetAuctionsParams {
  status?: 'ACTIVA' | 'CERRADA' | 'CANCELADA'
  page?: number
  page_size?: number
}

export async function getAuctions(
  params?: GetAuctionsParams,
): Promise<PaginatedResponse<Auction> | Auction[]> {
  const { data } = await axiosInstance.get<PaginatedResponse<Auction> | Auction[]>(
    '/api/v1/auctions/',
    { params },
  )
  return data
}

export async function getAuctionById(id: string | number): Promise<Auction & { bids?: Bid[] }> {
  const { data } = await axiosInstance.get<Auction & { bids?: Bid[] }>(
    `/api/v1/auctions/${id}/`,
  )
  return data
}

export async function placeBid(
  auctionId: string | number,
  amount: number,
): Promise<{ detail: string; bid_id: string }> {
  const { data } = await axiosInstance.post<{ detail: string; bid_id: string }>(
    `/api/v1/auctions/${auctionId}/bid/`,
    { amount },
  )
  return data
}

export async function closeAuction(auctionId: string | number): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(
    `/api/v1/auctions/${auctionId}/close/`,
  )
  return data
}
