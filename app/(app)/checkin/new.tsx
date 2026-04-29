import { CheckinForm } from '@/components/CheckinForm';
import { useProfile } from '@/state/queries';

export default function NewCheckin() {
  const profile = useProfile();
  const units = profile.data?.unitSystem ?? 'metric';
  return <CheckinForm existing={null} units={units} />;
}
