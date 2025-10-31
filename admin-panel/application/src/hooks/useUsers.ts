import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { usersService } from '@/services';
import type { User, QueryParams } from '@/types';

const QUERY_KEYS = {
  users: (params?: QueryParams) => ['users', params],
  user: (id: string) => ['users', id],
};

export const useUsers = (params?: QueryParams) => {
  return useQuery({
    queryKey: QUERY_KEYS.users(params),
    queryFn: () => usersService.getUsers(params),
  });
};

export const useUser = (id: string) => {
  return useQuery({
    queryKey: QUERY_KEYS.user(id),
    queryFn: () => usersService.getUserById(id),
    enabled: !!id,
  });
};

export const useUpdateUser = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<User> }) =>
      usersService.updateUser(id, data),
    onSuccess: (updatedUser) => {
      queryClient.setQueryData(QUERY_KEYS.user(updatedUser.id), updatedUser);
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
};

export const useDeleteUser = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: usersService.deleteUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
};

export const useToggleUserStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: usersService.toggleUserStatus,
    onSuccess: (updatedUser) => {
      queryClient.setQueryData(QUERY_KEYS.user(updatedUser.id), updatedUser);
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
};

export const useExportUsers = () => {
  return useMutation({
    mutationFn: (params?: QueryParams) => usersService.exportUsers(params),
    onSuccess: (blob) => {
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `users-export-${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    },
  });
};