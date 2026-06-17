import { useEffect, useState } from "react";
import { httpsCallable } from "firebase/functions";
import { functions } from "./firebase";

interface DraftOption {
  option: string;
  rationale: string;
  citations?: string[];
}
interface ClinicalDraft {
  draftAssessment: string;
  differentialConsiderations?: string[];
  options: DraftOption[];
  uncertaintiesForClinician?: string[];
}
interface Review {
  id: string;
  uid: string;
  reportId: string;
  status: string;
  draft: ClinicalDraft;
}

/**
 * Review/edit/sign-off workflow (SPEC §3.8, §2.7). The clinician edits the draft into the
 * final, clinician-authored guidance; only "Approve & release" sends anything to the patient.
 */
export function ReviewConsole() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [selected, setSelected] = useState<Review | null>(null);
  const [edited, setEdited] = useState("");
  const [notes, setNotes] = useState("");
  const [status, setStatus] = useState<string | null>(null);

  async function load() {
    try {
      const res = await httpsCallable<unknown, { reviews: Review[] }>(functions, "listClinicalReviews")();
      setReviews(res.data.reviews ?? []);
    } catch (err) {
      setStatus(String(err));
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function signOff(decision: "approved" | "declined") {
    if (!selected) return;
    setStatus("Submitting…");
    try {
      await httpsCallable(functions, "signOffClinicalReview")({
        reviewId: selected.id,
        decision,
        editedContent: decision === "approved" ? edited : undefined,
        clinicianNotes: notes,
      });
      setStatus(`Review ${decision}.`);
      setSelected(null);
      await load();
    } catch (err) {
      setStatus(String(err));
    }
  }

  return (
    <div style={{ display: "grid", gridTemplateColumns: "280px 1fr", gap: 16 }}>
      <aside>
        <h2 style={{ fontSize: 16 }}>Queue ({reviews.length})</h2>
        {reviews.map((r) => (
          <button
            key={r.id}
            onClick={() => {
              setSelected(r);
              setEdited(r.draft?.draftAssessment ?? "");
              setNotes("");
            }}
            style={{ display: "block", width: "100%", textAlign: "left", marginBottom: 6 }}
          >
            {r.reportId.slice(0, 8)} — {r.status}
          </button>
        ))}
        {reviews.length === 0 && <p style={{ color: "#666" }}>No pending reviews.</p>}
      </aside>

      <section>
        {!selected ? (
          <p>Select a review from the queue.</p>
        ) : (
          <div style={{ display: "grid", gap: 12 }}>
            <h2 style={{ fontSize: 16 }}>AI DRAFT (decision support only — not yet shown to patient)</h2>
            <div style={{ background: "#f5f5f5", padding: 12, borderRadius: 8, fontSize: 14 }}>
              <p><strong>Draft assessment:</strong> {selected.draft?.draftAssessment}</p>
              <strong>Options:</strong>
              <ul>
                {selected.draft?.options?.map((o, i) => (
                  <li key={i}>
                    {o.option} — <em>{o.rationale}</em>
                    {o.citations?.length ? ` [${o.citations.join("; ")}]` : ""}
                  </li>
                ))}
              </ul>
              {selected.draft?.uncertaintiesForClinician?.length ? (
                <>
                  <strong>Uncertainties:</strong>
                  <ul>{selected.draft.uncertaintiesForClinician.map((u, i) => <li key={i}>{u}</li>)}</ul>
                </>
              ) : null}
            </div>

            <label>
              <strong>Clinician-authored guidance (this is what the patient will see):</strong>
              <textarea value={edited} onChange={(e) => setEdited(e.target.value)} rows={10} style={{ width: "100%" }} />
            </label>
            <label>
              Clinician notes (internal):
              <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={3} style={{ width: "100%" }} />
            </label>

            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={() => signOff("approved")} style={{ background: "#166534", color: "white", padding: "8px 16px" }}>
                Approve &amp; release to patient
              </button>
              <button onClick={() => signOff("declined")} style={{ padding: "8px 16px" }}>
                Decline
              </button>
            </div>
            {status && <p>{status}</p>}
          </div>
        )}
      </section>
    </div>
  );
}
