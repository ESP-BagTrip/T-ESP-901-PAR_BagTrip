'use client'

import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Checkbox } from '@/components/ui/checkbox'
import { ScrollArea } from '@/components/ui/scroll-area'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { adminService, usersService } from '@/services'

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

  return (
    <Dialog open={open} onOpenChange={next => !next && onClose()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Envoyer une notification</DialogTitle>
          <DialogDescription>
            Diffuse une notification push aux utilisateurs sélectionnés.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="notif-title">Titre</Label>
            <Input
              id="notif-title"
              value={title}
              onChange={e => setTitle(e.target.value)}
              placeholder="Titre de la notification"
              maxLength={200}
            />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="notif-body">Message</Label>
            <Textarea
              id="notif-body"
              value={body}
              onChange={e => setBody(e.target.value)}
              placeholder="Corps du message"
              maxLength={1000}
              rows={3}
            />
          </div>

          <div className="flex items-center gap-2">
            <Checkbox
              id="notif-all"
              checked={sendToAll}
              onCheckedChange={checked => setSendToAll(checked === true)}
            />
            <Label htmlFor="notif-all" className="cursor-pointer font-normal">
              Envoyer à tous les utilisateurs
            </Label>
          </div>

          {!sendToAll && (
            <div className="space-y-1.5">
              <Label>
                Utilisateurs ({selectedUserIds.length} sélectionné
                {selectedUserIds.length > 1 ? 's' : ''})
              </Label>
              <ScrollArea className="h-40 rounded-md border border-border">
                <div className="space-y-1 p-2">
                  {users.map(user => (
                    <label
                      key={user.id}
                      className="flex cursor-pointer items-center gap-2 rounded px-1 py-1 text-sm hover:bg-muted"
                    >
                      <Checkbox
                        checked={selectedUserIds.includes(user.id)}
                        onCheckedChange={() => toggleUser(user.id)}
                      />
                      <span className="truncate">{user.email}</span>
                    </label>
                  ))}
                </div>
              </ScrollArea>
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={sending}>
              Annuler
            </Button>
            <Button type="submit" disabled={sending}>
              {sending ? 'Envoi...' : 'Envoyer'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
