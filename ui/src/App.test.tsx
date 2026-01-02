import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import App from './App';
import { MemoryRouter } from 'react-router-dom';

describe('App', () => {
  it('renders list heading', () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => [],
    } as Response);
    render(
      <MemoryRouter>
        <App />
      </MemoryRouter>,
    );
    return waitFor(() => {
      expect(screen.getByText(/スポット一覧/i)).toBeInTheDocument();
    });
  });
});
