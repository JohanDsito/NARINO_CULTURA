import axiosInstance from './axiosInstance'

export interface ChatHistoryItem {
  role: 'user' | 'model'
  text: string
}

export interface ChatResponse {
  reply: string
  session_id?: string
  model_used?: string
}

export async function sendChatMessage(
  message: string,
  history: ChatHistoryItem[] = [],
): Promise<ChatResponse> {
  const { data } = await axiosInstance.post<ChatResponse>('/api/v1/chat/', {
    message,
    history,
  })
  return data
}
