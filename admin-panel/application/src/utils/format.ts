import { format, formatDistanceToNow } from 'date-fns';
import { fr } from 'date-fns/locale';
import { DATE_FORMATS } from './constants';

export const formatDate = (date: string | Date, formatString = DATE_FORMATS.DISPLAY): string => {
  const dateObject = typeof date === 'string' ? new Date(date) : date;
  return format(dateObject, formatString, { locale: fr });
};

export const formatDateTime = (date: string | Date): string => {
  const dateObject = typeof date === 'string' ? new Date(date) : date;
  return format(dateObject, DATE_FORMATS.DISPLAY_WITH_TIME, { locale: fr });
};

export const formatRelativeTime = (date: string | Date): string => {
  const dateObject = typeof date === 'string' ? new Date(date) : date;
  return formatDistanceToNow(dateObject, { addSuffix: true, locale: fr });
};

export const formatCurrency = (amount: number, currency = 'EUR'): string => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency,
  }).format(amount);
};

export const formatNumber = (num: number): string => {
  return new Intl.NumberFormat('fr-FR').format(num);
};

export const formatPercentage = (value: number, decimals = 1): string => {
  return `${value.toFixed(decimals)}%`;
};

export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength)}...`;
};