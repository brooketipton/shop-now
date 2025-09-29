public with sharing class StringUtil {
    public static String normalizeName(String name) {
        if (name == null) {
            return '';
        }

        String normalizedName = name.toLowerCase().replaceAll('[^a-z0-9 ]','').trim();
        normalizedName = normalizedName.replaceAll('\\s+', ' ');

        return normalizedName;
    }

    public static String normalizePhone(String phone) {
        if (phone == null) {
            return '';
        }

        return phone.replaceAll('[^0-9]', '');
    }

    public static String normalizeEmail(String email) {
        if (email == null) {
            return '';
        }
        
        return email.toLowerCase().trim();
    }
}
