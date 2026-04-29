import {
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query';

import {
  deleteCheckin,
  listCheckins,
  saveCheckin,
} from '@/data/repositories/checkins';
import {
  loadProfile,
  saveProfile,
} from '@/data/repositories/profile';
import { syncNow } from '@/data/sync/sync-service';
import { useAuthStore } from '@/state/auth-store';
import type { BodyCheckin, Profile } from '@/types';

export const checkinsKey = (userId: string) => ['checkins', userId] as const;
export const profileKey = (userId: string) => ['profile', userId] as const;

export function useCheckins() {
  const userId = useAuthStore((s) => s.user?.id ?? null);
  return useQuery<BodyCheckin[]>({
    queryKey: userId ? checkinsKey(userId) : ['checkins', 'anon'],
    enabled: !!userId,
    queryFn: async () => {
      if (!userId) return [];
      void syncNow();
      return listCheckins(userId);
    },
  });
}

export function useProfile() {
  const userId = useAuthStore((s) => s.user?.id ?? null);
  return useQuery<Profile | null>({
    queryKey: userId ? profileKey(userId) : ['profile', 'anon'],
    enabled: !!userId,
    queryFn: async () => {
      if (!userId) return null;
      return loadProfile(userId);
    },
  });
}

export function useSaveCheckin() {
  const qc = useQueryClient();
  const userId = useAuthStore((s) => s.user?.id ?? null);
  return useMutation({
    mutationFn: (c: BodyCheckin) => saveCheckin(c),
    onSuccess: () => {
      if (userId) qc.invalidateQueries({ queryKey: checkinsKey(userId) });
    },
  });
}

export function useDeleteCheckin() {
  const qc = useQueryClient();
  const userId = useAuthStore((s) => s.user?.id ?? null);
  return useMutation({
    mutationFn: (id: string) => deleteCheckin(id),
    onSuccess: () => {
      if (userId) qc.invalidateQueries({ queryKey: checkinsKey(userId) });
    },
  });
}

export function useSaveProfile() {
  const qc = useQueryClient();
  const userId = useAuthStore((s) => s.user?.id ?? null);
  return useMutation({
    mutationFn: (p: Profile) => saveProfile(p),
    onSuccess: () => {
      if (userId) qc.invalidateQueries({ queryKey: profileKey(userId) });
    },
  });
}
