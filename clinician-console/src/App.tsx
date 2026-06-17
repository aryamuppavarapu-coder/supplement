import { useEffect, useState } from "react";
import { onAuthStateChanged, signInWithEmailAndPassword, signOut, type User } from "firebase/auth";
import { auth } from "./firebase";
import { ReviewConsole } from "./ReviewConsole";

const banner: React.CSSProperties = {
  background: "#7f1d1d",
  color: "white",
  padding: "10px 16px",
  fontSize: 13,
  textAlign: "center",
};

export function App() {
  const [user, setUser] = useState<User | null>(null);
  const [isClinician, setIsClinician] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        const token = await u.getIdTokenResult();
        setIsClinician(token.claims.clinician === true);
      } else {
        setIsClinician(false);
      }
      setLoading(false);
    });
  }, []);

  return (
    <div style={{ fontFamily: "system-ui, sans-serif", maxWidth: 1000, margin: "0 auto" }}>
      <div style={banner}>
        ⛔ Tier 2 (clinical). No AI output reaches a patient without a licensed clinician's
        sign-off (SPEC §2.7). This console is disabled in the backend until every §14
        prerequisite (medical director, CPOM, licensing, insurance, HIPAA, FDA determination) exists.
      </div>

      <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: 16 }}>
        <h1 style={{ fontSize: 20, margin: 0 }}>Supplement — Clinician Console</h1>
        {user && <button onClick={() => signOut(auth)}>Sign out</button>}
      </header>

      <main style={{ padding: 16 }}>
        {loading ? (
          <p>Loading…</p>
        ) : !user ? (
          <SignIn />
        ) : !isClinician ? (
          <p>
            Your account doesn't have clinician access. A `clinician` custom claim must be set
            on your account by an administrator.
          </p>
        ) : (
          <ReviewConsole />
        )}
      </main>
    </div>
  );
}

function SignIn() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      setError(String(err));
    }
  }

  return (
    <form onSubmit={submit} style={{ display: "grid", gap: 8, maxWidth: 320 }}>
      <h2>Clinician sign in</h2>
      <input placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
      <input type="password" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button type="submit">Sign in</button>
      {error && <p style={{ color: "crimson" }}>{error}</p>}
    </form>
  );
}
