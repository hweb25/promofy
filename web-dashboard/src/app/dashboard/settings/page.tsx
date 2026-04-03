"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import type { Business } from "@/types";
import toast from "react-hot-toast";
import { Store, MapPin, Clock, Save } from "lucide-react";

const categories = [
  { value: "restaurant", label: "Restaurant" },
  { value: "bar", label: "Bar" },
  { value: "cafe", label: "Cafe" },
  { value: "food_truck", label: "Food Truck" },
  { value: "bakery", label: "Bakery" },
  { value: "other", label: "Other" },
];

export default function SettingsPage() {
  const [business, setBusiness] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // Form
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("restaurant");
  const [address, setAddress] = useState("");
  const [city, setCity] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");

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
      setName(biz.name);
      setDescription(biz.description || "");
      setCategory(biz.category);
      setAddress(biz.address_line1);
      setCity(biz.city);
      setPhone(biz.phone || "");
      setEmail(biz.email || "");
    }
    setLoading(false);
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);

    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) throw new Error("Not authenticated");

      const payload = {
        name,
        description,
        category,
        address_line1: address,
        city,
        country: "CO",
        phone,
        email,
        location: `POINT(-74.0721 4.7110)`, // TODO: geocode from address
      };

      if (business) {
        const { error } = await supabase
          .from("businesses")
          .update(payload)
          .eq("id", business.id);
        if (error) throw error;
        toast.success("Settings saved!");
      } else {
        const { error } = await supabase.from("businesses").insert({
          ...payload,
          owner_id: user.id,
        });
        if (error) throw error;
        toast.success("Business created!");
      }
      loadData();
    } catch (err: any) {
      toast.error(err.message || "Failed to save");
    } finally {
      setSaving(false);
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
    <div className="max-w-2xl">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">
          {business ? "Business Settings" : "Set Up Your Business"}
        </h1>
        <p className="text-gray-500">
          {business
            ? "Update your business information"
            : "Fill in your details to get started"}
        </p>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* Basic Info */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-primary-50 rounded-xl flex items-center justify-center">
              <Store className="w-5 h-5 text-primary-500" />
            </div>
            <h2 className="text-lg font-bold">Basic Information</h2>
          </div>

          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">
                Business Name *
              </label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="input"
                required
                placeholder="e.g., La Esquina Bar"
              />
            </div>

            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">
                Description
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="input"
                rows={3}
                placeholder="Tell customers about your business..."
              />
            </div>

            <div>
              <label className="text-sm font-medium text-gray-700 mb-2 block">
                Category *
              </label>
              <div className="flex flex-wrap gap-2">
                {categories.map((c) => (
                  <button
                    key={c.value}
                    type="button"
                    onClick={() => setCategory(c.value)}
                    className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${
                      category === c.value
                        ? "bg-primary-500 text-white"
                        : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    }`}
                  >
                    {c.label}
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1 block">
                  Phone
                </label>
                <input
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="input"
                  placeholder="+57 300 123 4567"
                />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1 block">
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="input"
                  placeholder="contact@business.com"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Location */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-cyan-50 rounded-xl flex items-center justify-center">
              <MapPin className="w-5 h-5 text-cyan-500" />
            </div>
            <h2 className="text-lg font-bold">Location</h2>
          </div>

          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">
                Address *
              </label>
              <input
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                className="input"
                required
                placeholder="Street address"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">
                City *
              </label>
              <input
                value={city}
                onChange={(e) => setCity(e.target.value)}
                className="input"
                required
                placeholder="e.g., Bogota"
              />
            </div>

            {/* Map placeholder */}
            <div className="h-48 bg-gray-100 rounded-xl flex items-center justify-center text-gray-400">
              <div className="text-center">
                <MapPin className="w-8 h-8 mx-auto mb-2" />
                <p className="text-sm">
                  Map preview will appear here after saving
                </p>
              </div>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={saving}
          className="btn-primary w-full flex items-center justify-center gap-2"
        >
          <Save className="w-5 h-5" />
          {saving
            ? "Saving..."
            : business
            ? "Save Changes"
            : "Create Business"}
        </button>
      </form>
    </div>
  );
}
