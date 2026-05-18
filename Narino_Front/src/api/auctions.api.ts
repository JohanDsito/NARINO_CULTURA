import axiosInstance from './axiosInstance'
import type { Auction } from '@/types/auth'

export interface GetAuctionsParams {
  status?: string
  page?: number
  page_size?: number
}

export async function getAuctions(params?: GetAuctionsParams) {
  const { data } = await axiosInstance.get<Auction[]>('/api/v1/auctions/', { params })
  return data
}

export async function getAuctionById(id: string | number) {
  const { data } = await axiosInstance.get<Auction>(`/api/v1/auctions/${id}/`)
  return data
}
