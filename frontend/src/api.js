const BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8080";

export function authHeader(auth) {
    if (!auth || !auth.username || !auth.password) {
        return {};
    }
    const token = btoa(`${auth.username}:${auth.password}`);
    return { Authorization: `Basic ${token}` };
}

async function handleResponse(res) {
    const contentType = res.headers.get("content-type");
    if (!contentType || !contentType.includes("application/json")) {
        throw new Error(`Beklenmeyen yanıt formatı: ${res.status} ${res.statusText}`);
    }

    const data = await res.json();
    
    // ApiResponse formatını kontrol et
    if (data.success !== undefined) {
        if (!data.success) {
            const error = new Error(data.message || "Bir hata oluştu");
            error.data = data;
            error.status = res.status;
            throw error;
        }
        return data.data !== undefined ? data.data : data;
    }
    
    // Eski format (backward compatibility)
    if (!res.ok) {
        const error = new Error(data.message || data.error || res.statusText);
        error.data = data;
        error.status = res.status;
        throw error;
    }
    
    return data;
}

export async function apiGet(path, auth) {
    try {
        const res = await fetch(`${BASE_URL}${path}`, {
            headers: { ...authHeader(auth) },
        });
        return await handleResponse(res);
    } catch (error) {
        console.error(`API GET hatası [${path}]:`, error);
        throw error;
    }
}

export async function apiPost(path, body, auth) {
    try {
        const res = await fetch(`${BASE_URL}${path}`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                ...authHeader(auth),
            },
            body: JSON.stringify(body),
        });
        return await handleResponse(res);
    } catch (error) {
        console.error(`API POST hatası [${path}]:`, error);
        throw error;
    }
}

export async function apiPatch(path, auth, body = null) {
    try {
        const headers = { ...authHeader(auth) };
        if (body) {
            headers["Content-Type"] = "application/json";
        }
        
        const res = await fetch(`${BASE_URL}${path}`, {
            method: "PATCH",
            headers,
            body: body ? JSON.stringify(body) : undefined,
        });
        return await handleResponse(res);
    } catch (error) {
        console.error(`API PATCH hatası [${path}]:`, error);
        throw error;
    }
}

export async function apiDelete(path, auth) {
    try {
        const res = await fetch(`${BASE_URL}${path}`, {
            method: "DELETE",
            headers: { ...authHeader(auth) },
        });
        return await handleResponse(res);
    } catch (error) {
        console.error(`API DELETE hatası [${path}]:`, error);
        throw error;
    }
}
