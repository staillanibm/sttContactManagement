CREATE TABLE contact_roles (
    id VARCHAR(36) PRIMARY KEY,
    contact_id VARCHAR(36) NOT NULL,
    account_id VARCHAR(36) NOT NULL,
    contact_role VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contact_id FOREIGN KEY (contact_id)
        REFERENCES contacts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE INDEX contact_roles_contact_id_idx ON public.contact_roles USING btree (contact_id);

