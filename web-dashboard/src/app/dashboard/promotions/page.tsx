"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import type { Promotion, Business } from "@/types";
import toast from "react-hot-toast";
import {
  Plus,
  Megaphone,
  Trash2,
  Pause,
  Play,
  Calendar,
  Clock,
} from "lucide-react";
import { format } from "date-fns";

export default function PromotionsPage() {
  const [business, setBusiness] = useState<Business | null>(null);
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);

  // Form state
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [discountType, setDiscountType] = useState("percentage");
  const [discountValue, setDiscountValue] = useState("");
  const [startsAt, setStartsAt] = useState(
    format(new Date(), "yyyy-MM-dd'T'HH:mm")
  );
  const [endsAt, setEndsAt] = useState(
    format(new Date(Date.now() + 7 * 86400000), "yyyy-MM-dd'T'HH:mm")
  );
  const [activeTimeStart, setActiveTimeStart] = useState("09:00");
  const [activeTimeEnd, setActiveTimeEnd] = useState("22:00");
  const [maxRedemptions, setMaxRedemptions] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;

    const { data: biz } = await supabase
      .from("businesses")
      .select("*")
      .eq("owner_id", user.id)
      .single();

    if (biz) {
      setBusiness(biz);
      const { data: promos } = await supabase
        .from("promotions")
        .select("*")
        .eq("business_id", biz.id)
        .order("created_at", { ascending: false });
      if (promos) setPromotions(promos);
    }
    setLoading(false);
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!business) return;
    setSaving(true);

    try {
      const { error } = await supabase.from("promotions").insert({
        business_id: business.id,
        title,
        description,
        discount_type: discountType,
        discount_value: parseFloat(discountValue) || 0,
        status: "active",
        starts_at: new Date(startsAt).toISOString(),
        ends_at: new Date(endsAt).toISOString(),
        active_time_start: activeTimeStart,
        active_time_end: activeTimeEnd,
        max_total_redemptions: maxRedemptions
          ? parseInt(maxRedemptions)
          : null,
        max_per_user: 1,
        active_days: [
          "monday",
          "tuesday",
          "wednesday",
          "thursday",
          "friday",
          "saturday",
          "sunday",
        ],
      });

      if (error) throw error;

      toast.success("Promotion created!");
      setShowForm(false);
      resetForm();
      loadData();
    } catch (err: any) {
      toast.error(err.message || "Failed to create promotion");
    } finally {
      setSaving(false);
    }
  }

  function resetForm() {
    setTitle("");
    setDescription("");
    setDiscountType("percentage");
    setDiscountValue("");
    setMaxRedemptions("");
  }

  async function toggleStatus(promo: Promotion) {
    const newStatus = promo.status === "active" ? "paused" : "active";
    const { error } = await supabase
      .from("promotions")
      .update({ status: newStatus })
      .eq("id", promo.id);

    if (error) {
      toast.error("Failed to update");
    } else {
      toast.success(`Promotion ${newStatus}`);
      loadData();
    }
  }

  async function deletePromo(id: string) {
    if (!confirm("Delete this promotion?")) return;
    const { error } = await supabase.from("promotions").delete().eq("id", id);
    if (error) {
      toast.error("Failed to delete");
    } else {
      toast.success("Deleted");
      loadData();
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Promotions</h1>
          <p className="text-gray-500">Create and manage your promotions</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          {showForm ? "Cancel" : "New Promotion"}
        </button>
      </div>

      {/* Create Form */}
      {showForm && (
        <form onSubmit={handleCreate} className="card p-6 mb-8 space-y-4">
          <h3 className="text-lg font-bold mb-4">Create Promotion</h3>

          {/* Quick Templates */}
          <div className="flex gap-2 flex-wrap">
            {[
              { t: "Happy Hour 2x1", dt: "bogo", dv: "0" },
              { t: "20% Off Total", dt: "percentage", dv: "20" },
              { t: "Free Dessert", dt: "free_item", dv: "0" },
              { t: "$5 Off", dt: "fixed", dv: "5" },
            ].map((tpl) => (
              <button
                key={tpl.t}
                type="button"
                onClick={() => {
                  setTitle(tpl.t);
                  setDiscountType(tpl.dt);
                  setDiscountValue(tpl.dv);
                }}
                className="px-3 py-1.5 text-sm bg-primary-50 text-primary-600 rounded-lg hover:bg-primary-100 transition-colors"
              >
                {tpl.t}
              </button>
            ))}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <input
              placeholder="Promotion Title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="input"
              required
            />
            <select
              value={discountType}
              onChange={(e) => setDiscountType(e.target.value)}
              className="input"
            >
              <option value="percentage">% Off</option>
              <option value="fixed">$ Off</option>
              <option value="bogo">2x1 (BOGO)</option>
              <option value="free_item">Free Item</option>
            </select>
          </div>

          <textarea
            placeholder="Description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="input"
            rows={2}
            required
          />

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {(discountType === "percentage" || discountType === "fixed") && (
              <input
                type="number"
                placeholder={
                  discountType === "percentage" ? "Discount %" : "Discount $"
                }
                value={discountValue}
                onChange={(e) => setDiscountValue(e.target.value)}
                className="input"
              />
            )}
            <input
              type="datetime-local"
              value={startsAt}
              onChange={(e) => setStartsAt(e.target.value)}
              className="input"
            />
            <input
              type="datetime-local"
              value={endsAt}
              onChange={(e) => setEndsAt(e.target.value)}
              className="input"
            />
            <input
              type="number"
              placeholder="Max redemptions (empty = unlimited)"
              value={maxRedemptions}
              onChange={(e) => setMaxRedemptions(e.target.value)}
              className="input"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-sm text-gray-500 mb-1 block">
                Active from
              </label>
              <input
                type="time"
                value={activeTimeStart}
                onChange={(e) => setActiveTimeStart(e.target.value)}
                className="input"
              />
            </div>
            <div>
              <label className="text-sm text-gray-500 mb-1 block">
                Active until
              </label>
              <input
                type="time"
                value={activeTimeEnd}
                onChange={(e) => setActiveTimeEnd(e.target.value)}
                className="input"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={saving}
            className="btn-primary w-full"
          >
            {saving ? "Creating..." : "Publish Promotion"}
          </button>
        </form>
      )}

      {/* Promotions List */}
      <div className="card overflow-hidden">
        {promotions.length === 0 ? (
          <div className="p-16 text-center text-gray-500">
            <Megaphone className="w-16 h-16 mx-auto mb-4 text-gray-200" />
            <p className="text-lg font-medium">No promotions yet</p>
            <p className="mt-1">
              Create your first promotion to attract customers!
            </p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">
                  Promotion
                </th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">
                  Status
                </th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">
                  Redeemed
                </th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">
                  Schedule
                </th>
                <th className="px-6 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {promotions.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium">{p.title}</div>
                    <div className="text-sm text-gray-500 truncate max-w-xs">
                      {p.description}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`inline-flex text-xs font-semibold px-3 py-1 rounded-full ${
                        p.status === "active"
                          ? "bg-green-50 text-green-600"
                          : p.status === "paused"
                          ? "bg-yellow-50 text-yellow-600"
                          : p.status === "expired"
                          ? "bg-gray-100 text-gray-500"
                          : "bg-blue-50 text-blue-600"
                      }`}
                    >
                      {p.status.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="font-semibold">
                      {p.current_redemptions}
                    </span>
                    <span className="text-gray-400">
                      {p.max_total_redemptions
                        ? ` / ${p.max_total_redemptions}`
                        : ""}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      {format(new Date(p.starts_at), "MMM dd")} -{" "}
                      {format(new Date(p.ends_at), "MMM dd")}
                    </div>
                    {p.active_time_start && (
                      <div className="flex items-center gap-1 mt-1">
                        <Clock className="w-4 h-4" />
                        {p.active_time_start} - {p.active_time_end}
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 justify-end">
                      <button
                        onClick={() => toggleStatus(p)}
                        className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
                        title={
                          p.status === "active" ? "Pause" : "Activate"
                        }
                      >
                        {p.status === "active" ? (
                          <Pause className="w-4 h-4 text-yellow-500" />
                        ) : (
                          <Play className="w-4 h-4 text-green-500" />
                        )}
                      </button>
                      <button
                        onClick={() => deletePromo(p.id)}
                        className="p-2 rounded-lg hover:bg-red-50 transition-colors"
                      >
                        <Trash2 className="w-4 h-4 text-red-400" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
