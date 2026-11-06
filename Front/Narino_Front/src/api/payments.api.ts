import axiosInstance from './axiosInstance'

export interface InitiatePaymentPayload {
  amount: number
  currency: string
  order_id?: number | string
  payment_method?: string
  metadata?: Record<string, unknown>
}

export interface Transaction {
  id: number
  uuid: string
  amount: number
  currency: string
  status: string
  created_at: string
  updated_at: string
}

export async function initiatePayment(payload: InitiatePaymentPayload) {
  const { data } = await axiosInstance.post<Record<string, unknown>>('/api/v1/payments/initiate/', payload)
  return data
}

export async function getTransactions() {
  const { data } = await axiosInstance.get<Transaction[]>('/api/v1/payments/transactions/')
  return data
}

export async function getTransactionReceipt(uuid: string) {
  const { data } = await axiosInstance.get<Record<string, unknown>>(`/api/v1/payments/transactions/${uuid}/receipt/`)
  return data
}
