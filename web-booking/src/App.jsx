import { useState } from 'react'
import './App.css'

function App() {
  const [formData, setFormData] = useState({
    fullName: '',
    phoneNumber: '',
    email: '',
    date: '',
    notes: ''
  })
  const [isSuccess, setIsSuccess] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')

    try {
      // Use relative path so it works when served from backend
      const response = await fetch('/api/public/book', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Bir hata oluştu')
      }

      setIsSuccess(true)
      setFormData({ fullName: '', phoneNumber: '', email: '', date: '', notes: '' })
    } catch (err) {
      setError(err.message)
    } finally {
      setIsLoading(false)
    }
  }

  if (isSuccess) {
    return (
      <div className="container">
        <div className="card">
          <div className="success-message">
            <div className="check-icon">✓</div>
            <h2 className="success-title">Randevunuz Alındı!</h2>
            <p className="success-desc">
              Talebiniz bize ulaştı. En kısa sürede sizinle iletişime geçip randevunuzu onaylayacağız.
            </p>
            <button className="back-btn" onClick={() => setIsSuccess(false)}>
              Yeni Randevu Al
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="container">
      <div className="card">
        <div className="header">
          <h1 className="logo-text">ICY Clinic</h1>
          <p className="subtitle">Online Randevu Formu</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Ad Soyad</label>
            <input
              type="text"
              name="fullName"
              required
              placeholder="Adınız Soyadınız"
              value={formData.fullName}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label>Telefon Numarası</label>
            <input
              type="tel"
              name="phoneNumber"
              required
              placeholder="05XX XXX XX XX"
              value={formData.phoneNumber}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label>E-posta Adresi (Opsiyonel)</label>
            <input
              type="email"
              name="email"
              placeholder="ornek@email.com"
              value={formData.email}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label>Randevu Tarihi</label>
            <input
              type="datetime-local"
              name="date"
              required
              value={formData.date}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label>Notlar / Şikayetiniz</label>
            <textarea
              name="notes"
              rows="3"
              placeholder="Kısaca şikayetinizden bahsedebilirsiniz..."
              value={formData.notes}
              onChange={handleChange}
            ></textarea>
          </div>

          {error && <p style={{ color: 'red', marginBottom: '15px', fontSize: '0.9rem', textAlign: 'center' }}>{error}</p>}

          <button type="submit" className="submit-btn" disabled={isLoading}>
            {isLoading ? 'Gönderiliyor...' : 'Randevu Oluştur'}
          </button>
        </form>
      </div>
    </div>
  )
}

export default App
