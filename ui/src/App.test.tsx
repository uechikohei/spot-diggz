import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders list heading', () => {
    render(<App />);
    expect(screen.getByText(/スポット一覧/i)).toBeInTheDocument();
  });
});
