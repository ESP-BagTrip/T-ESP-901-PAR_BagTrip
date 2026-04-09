'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { adminService } from '@/services'
import { usersService } from '@/services'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

interface SendNotificationModalProps {
  open: boolean
  onClose: () => void
}

export function SendNotificationModal({ open, onClose }: SendNotificationModalProps) {
  const queryClient = useQueryClient()
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [sendToAll, setSendToAll] = useState(true)
  const [selectedUserIds, setSelectedUserIds] = useState<string[]>([])
  const [sending, setSending] = useState(false)

  const { data: usersData } = useQuery({
    queryKey: ['users', 'all-for-notif'],
    queryFn: () => usersService.getUsers({ page: 1, limit: 100 }),
    enabled: open && !sendToAll,
  })

  const users = usersData?.data || []

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim() || !body.trim()) {
      toast.error('Titre et message sont requis')
      return
    }

    let userIds: string[]
    if (sendToAll) {
      const allUsers = await usersService.getUsers({ page: 1, limit: 10000 })
      userIds = allUsers.data.map(u => u.id)
    } else {
      userIds = selectedUserIds
    }

    if (userIds.length === 0) {
      toast.error('Sélectionnez au moins un utilisateur')
      return
    }

    setSending(true)
    try {
      const result = await adminService.sendNotification({
        user_ids: userIds,
        title: title.trim(),
        body: body.trim(),
        type: 'ADMIN',
      })
      toast.success(result.message)
      queryClient.invalidateQueries({ queryKey: ['admin', 'notifications'] })
      setTitle('')
      setBody('')
      setSelectedUserIds([])
      onClose()
    } catch {
      toast.error("Erreur lors de l'envoi")
    } finally {
      setSending(false)
    }
  }

  const toggleUser = (userId: string) => {
    setSelectedUserIds(prev =>
      prev.includes(userId) ? prev.filter(id => id !== userId) : [...prev, userId]
    )
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <h2 className="text-lg font-semibold mb-4">Envoyer une notification</h2>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Titre</label>
              <Input
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="Titre de la notification"
                maxLength={200}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
              <textarea
                value={body}
                onChange={e => setBody(e.target.value)}
                placeholder="Corps du message"
                maxLength={1000}
                rows={3}
                className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={sendToAll}
                  onChange={e => setSendToAll(e.target.checked)}
                  className="rounded"
                />
                Envoyer à tous les utilisateurs
              </label>
            </div>

            {!sendToAll && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Utilisateurs ({selectedUserIds.length} sélectionné
                  {selectedUserIds.length > 1 ? 's' : ''})
                </label>
                <div className="max-h-40 overflow-y-auto border rounded-md p-2 space-y-1">
                  {users.map(user => (
                    <label
                      key={user.id}
                      className="flex items-center gap-2 text-sm cursor-pointer hover:bg-gray-50 px-1 py-0.5 rounded"
                    >
                      <input
                        type="checkbox"
                        checked={selectedUserIds.includes(user.id)}
                        onChange={() => toggleUser(user.id)}
                        className="rounded"
                      />
                      {user.email}
                    </label>
                  ))}
                </div>
              </div>
            )}

            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={onClose} disabled={sending}>
                Annuler
              </Button>
              <Button type="submit" disabled={sending}>
                {sending ? 'Envoi...' : 'Envoyer'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
